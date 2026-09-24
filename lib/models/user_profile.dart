enum VerificationStatus { notStarted, pending, verified }

class UserProfile {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final int trustScore; // 0 to 100
  final bool isPhoneVerified;
  final bool isIdVerified;
  final bool isSelfieVerified;
  final String location;
  final String memberSince;
  final int activeListingsCount;
  final int successfulDealsCount;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.trustScore,
    this.isPhoneVerified = true,
    this.isIdVerified = false,
    this.isSelfieVerified = false,
    required this.location,
    required this.memberSince,
    this.activeListingsCount = 0,
    this.successfulDealsCount = 0,
  });

  bool get isFullyVerified => isPhoneVerified && isIdVerified && isSelfieVerified;

  UserProfile copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    double? rating,
    int? reviewCount,
    int? trustScore,
    bool? isPhoneVerified,
    bool? isIdVerified,
    bool? isSelfieVerified,
    String? location,
    String? memberSince,
    int? activeListingsCount,
    int? successfulDealsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      trustScore: trustScore ?? this.trustScore,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isIdVerified: isIdVerified ?? this.isIdVerified,
      isSelfieVerified: isSelfieVerified ?? this.isSelfieVerified,
      location: location ?? this.location,
      memberSince: memberSince ?? this.memberSince,
      activeListingsCount: activeListingsCount ?? this.activeListingsCount,
      successfulDealsCount: successfulDealsCount ?? this.successfulDealsCount,
    );
  }
}
