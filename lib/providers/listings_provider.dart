import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/db/database_helper.dart';
import '../models/listing_item.dart';

/// Seed loaded once at startup (after SQLite init) — overrides in `main()`.
final initialListingsProvider = Provider<List<ListingItem>>((ref) => const []);

class ListingsNotifier extends StateNotifier<List<ListingItem>> {
  ListingsNotifier(super.initialListings);

  Future<void> addListing(ListingItem newItem) async {
    state = [newItem, ...state];
    await DatabaseHelper.instance.insertListing(newItem);
  }

  Future<void> toggleBookmark(String id) async {
    bool? nowBookmarked;
    state = state.map((item) {
      if (item.id == id) {
        nowBookmarked = !item.isBookmarked;
        return item.copyWith(isBookmarked: nowBookmarked);
      }
      return item;
    }).toList();
    if (nowBookmarked != null) {
      await DatabaseHelper.instance.updateBookmark(id, nowBookmarked!);
    }
  }

  /// Re-reads all active listings from SQLite (source of truth).
  Future<void> refreshFromDb() async {
    state = await DatabaseHelper.instance.getListings();
  }

  ListingItem? getListingById(String id) {
    try {
      return state.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Core Listings State Provider (backed by SQLite `madeals.db`)
final listingsProvider =
    StateNotifierProvider<ListingsNotifier, List<ListingItem>>((ref) {
  return ListingsNotifier(ref.watch(initialListingsProvider));
});

/// True once the first SQLite load attempt has finished (success or not).
/// Screens show shimmer skeletons until this flips to true.
final bootCompletedProvider = StateProvider<bool>((ref) => false);

// App State Filter Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final selectedDistanceFilterProvider = StateProvider<double?>((ref) => null);
final selectedMaxPriceProvider = StateProvider<double?>((ref) => null);
final isVerifiedOnlyProvider = StateProvider<bool>((ref) => false);
final isMapViewProvider = StateProvider<bool>((ref) => true);

// Combined Filtered Listings Provider
// (data originates from SQLite; filters run in-memory for instant UI)
final filteredListingsProvider = Provider<List<ListingItem>>((ref) {
  final listings = ref.watch(listingsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(selectedCategoryProvider);
  final maxDistance = ref.watch(selectedDistanceFilterProvider);
  final maxPrice = ref.watch(selectedMaxPriceProvider);
  final verifiedOnly = ref.watch(isVerifiedOnlyProvider);

  return listings.where((item) {
    // Category filter
    if (category != 'All' && item.category.toLowerCase() != category.toLowerCase()) {
      return false;
    }

    // Search Query filter
    if (query.isNotEmpty) {
      final matchesTitle = item.title.toLowerCase().contains(query);
      final matchesDesc = item.description.toLowerCase().contains(query);
      final matchesLoc = item.location.toLowerCase().contains(query);
      final matchesTags = item.tags.any((t) => t.toLowerCase().contains(query));
      if (!matchesTitle && !matchesDesc && !matchesLoc && !matchesTags) {
        return false;
      }
    }

    // Distance filter
    if (maxDistance != null && item.distanceKm > maxDistance) {
      return false;
    }

    // Price filter
    if (maxPrice != null && item.price > maxPrice) {
      return false;
    }

    // Verified only
    if (verifiedOnly && !item.isVerified) {
      return false;
    }

    return true;
  }).toList();
});

// Single item provider family
final singleListingProvider = Provider.family<ListingItem?, String>((ref, id) {
  final listings = ref.watch(listingsProvider);
  try {
    return listings.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});
