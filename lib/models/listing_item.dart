class ListingItem {
  final String id;
  final String title;
  final double price;
  final String category; // 'Vehicles', 'Phones', 'Electronics', 'Property', 'Solar & Power', etc.
  final String location;
  final double distanceKm;
  final bool isVerified;
  final bool isFeatured;
  final bool isNegotiable;
  final List<String> images;
  final Map<String, String> specs;
  final String description;
  final bool allowsBarter;
  final String? tradeDetails;
  final String sellerName;
  final String sellerPhone;
  final double sellerRating;
  final int sellerReviewsCount;
  final String? sellerAvatar;
  final String timeListedAgo;
  final String meetupSpot;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final bool isBookmarked;

  const ListingItem({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.location,
    required this.distanceKm,
    this.isVerified = true,
    this.isFeatured = false,
    this.isNegotiable = true,
    required this.images,
    required this.specs,
    required this.description,
    this.allowsBarter = false,
    this.tradeDetails,
    required this.sellerName,
    required this.sellerPhone,
    this.sellerRating = 4.9,
    this.sellerReviewsCount = 24,
    this.sellerAvatar,
    this.timeListedAgo = '2h ago',
    this.meetupSpot = 'Harare CBD (Safe Daylight Zone)',
    this.latitude = -17.8292,
    this.longitude = 31.0522,
    this.tags = const [],
    this.isBookmarked = false,
  });

  String get formattedPrice => '\$${price % 1 == 0 ? price.toInt() : price.toStringAsFixed(2)}';
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get firstImage => images.isNotEmpty
      ? images.first
      : 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=600&auto=format&fit=crop&q=80';

  ListingItem copyWith({
    String? id,
    String? title,
    double? price,
    String? category,
    String? location,
    double? distanceKm,
    bool? isVerified,
    bool? isFeatured,
    bool? isNegotiable,
    List<String>? images,
    Map<String, String>? specs,
    String? description,
    bool? allowsBarter,
    String? tradeDetails,
    String? sellerName,
    String? sellerPhone,
    double? sellerRating,
    int? sellerReviewsCount,
    String? sellerAvatar,
    String? timeListedAgo,
    String? meetupSpot,
    double? latitude,
    double? longitude,
    List<String>? tags,
    bool? isBookmarked,
  }) {
    return ListingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      images: images ?? this.images,
      specs: specs ?? this.specs,
      description: description ?? this.description,
      allowsBarter: allowsBarter ?? this.allowsBarter,
      tradeDetails: tradeDetails ?? this.tradeDetails,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerReviewsCount: sellerReviewsCount ?? this.sellerReviewsCount,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      timeListedAgo: timeListedAgo ?? this.timeListedAgo,
      meetupSpot: meetupSpot ?? this.meetupSpot,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
