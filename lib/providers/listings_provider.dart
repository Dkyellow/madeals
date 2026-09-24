import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_item.dart';
import '../repositories/listing_repository.dart';

class ListingsNotifier extends StateNotifier<List<ListingItem>> {
  ListingsNotifier() : super(ListingRepository.getInitialListings());

  void addListing(ListingItem newItem) {
    state = [newItem, ...state];
  }

  void toggleBookmark(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isBookmarked: !item.isBookmarked);
      }
      return item;
    }).toList();
  }

  ListingItem? getListingById(String id) {
    try {
      return state.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Core Listings State Provider
final listingsProvider = StateNotifierProvider<ListingsNotifier, List<ListingItem>>((ref) {
  return ListingsNotifier();
});

// App State Filter Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final selectedDistanceFilterProvider = StateProvider<double?>((ref) => null);
final selectedMaxPriceProvider = StateProvider<double?>((ref) => null);
final isVerifiedOnlyProvider = StateProvider<bool>((ref) => false);
final isMapViewProvider = StateProvider<bool>((ref) => true);

// Combined Filtered Listings Provider
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
