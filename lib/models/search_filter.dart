enum DealType { all, forSale, auction, barter, jobService }

class SearchFilter {
  final String query;
  final String? category;
  final String location;
  final double? minPrice;
  final double? maxPrice;
  final DealType dealType;
  final bool verifiedSellersOnly;
  final String? condition;

  const SearchFilter({
    this.query = '',
    this.category,
    this.location = 'Harare, ZW',
    this.minPrice,
    this.maxPrice,
    this.dealType = DealType.all,
    this.verifiedSellersOnly = false,
    this.condition,
  });

  SearchFilter copyWith({
    String? query,
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    DealType? dealType,
    bool? verifiedSellersOnly,
    String? condition,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      category: category ?? this.category,
      location: location ?? this.location,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      dealType: dealType ?? this.dealType,
      verifiedSellersOnly: verifiedSellersOnly ?? this.verifiedSellersOnly,
      condition: condition ?? this.condition,
    );
  }

  List<String> get activeFilterTags {
    final List<String> tags = [];
    if (query.isNotEmpty) tags.add(query);
    if (maxPrice != null) tags.add('<\$${maxPrice!.toInt()}');
    if (location.isNotEmpty) tags.add(location.split(',').first.trim());
    if (category != null && category != 'All') tags.add(category!);
    return tags;
  }
}
