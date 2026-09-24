import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_filter.dart';

class SearchFilterNotifier extends StateNotifier<SearchFilter> {
  SearchFilterNotifier() : super(const SearchFilter(query: 'iphone 13 under 400 harare', maxPrice: 400));

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void setDealType(DealType type) {
    state = state.copyWith(dealType: type);
  }

  void setMaxPrice(double? maxPrice) {
    state = state.copyWith(maxPrice: maxPrice);
  }

  void setMinPrice(double? minPrice) {
    state = state.copyWith(minPrice: minPrice);
  }

  void setLocation(String location) {
    state = state.copyWith(location: location);
  }

  void toggleVerifiedOnly() {
    state = state.copyWith(verifiedSellersOnly: !state.verifiedSellersOnly);
  }

  void removeTag(String tag) {
    if (tag == state.query) {
      state = state.copyWith(query: '');
    } else if (tag.startsWith('<\$')) {
      state = state.copyWith(maxPrice: null);
    } else if (tag == state.location.split(',').first.trim()) {
      state = state.copyWith(location: 'All Zimbabwe');
    } else if (tag == state.category) {
      state = state.copyWith(category: null);
    }
  }

  void reset() {
    state = const SearchFilter();
  }
}

final searchFilterProvider = StateNotifierProvider<SearchFilterNotifier, SearchFilter>((ref) {
  return SearchFilterNotifier();
});

final isMapViewProvider = StateProvider<bool>((ref) => false);
