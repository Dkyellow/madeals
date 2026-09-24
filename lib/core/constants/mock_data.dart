import '../../models/listing_item.dart';
import '../../models/user_profile.dart';
import '../../models/trade_offer.dart';
import '../../models/auction_item.dart';
import '../../repositories/listing_repository.dart';

class MockData {
  static final UserProfile currentUser = UserProfile(
    id: 'user_01',
    name: 'Farai Moyo',
    phoneNumber: '+263 77 412 8990',
    email: 'farai.moyo@gmail.com',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    rating: 4.95,
    reviewCount: 38,
    trustScore: 98,
    isPhoneVerified: true,
    isIdVerified: true,
    isSelfieVerified: true,
    location: 'Harare Central, Zimbabwe',
    memberSince: 'March 2024',
    activeListingsCount: 3,
    successfulDealsCount: 14,
  );

  static final List<ListingItem> mockListings = ListingRepository.getInitialListings();

  static final List<TradeOffer> mockTradeOffers = [
    const TradeOffer(
      id: 'trade_01',
      offeredItem: 'M1 MacBook Air 8GB/256GB',
      requestedItem: 'iPad Pro 11" (M1/M2) + \$150 Cash',
      cashAdjustment: 150,
      userLocation: 'Mount Pleasant, Harare',
      timeAgo: '12m ago',
      isUrgent: true,
    ),
    const TradeOffer(
      id: 'trade_02',
      offeredItem: 'Sony PlayStation 5 Disc Edition + 2 Controllers',
      requestedItem: 'iPhone 13 Pro or Samsung S22 Ultra',
      userLocation: 'Avondale, Harare',
      timeAgo: '35m ago',
      isUrgent: false,
    ),
  ];

  static final List<AuctionItem> mockAuctions = [
    const AuctionItem(
      id: 'auc_01',
      title: 'iPhone 13 128GB Unlocked (Harare CBD)',
      imageUrl: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=400&auto=format&fit=crop&q=80',
      currentBid: 340,
      startingBid: 250,
      totalBids: 14,
      remainingTime: Duration(minutes: 1, seconds: 42),
      condition: '9/10 Battery 88%',
      location: 'Harare CBD',
      isVerified: true,
    ),
    const AuctionItem(
      id: 'auc_02',
      title: 'DJI Mini 2 4K Fly More Combo (3 Batteries)',
      imageUrl: 'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?w=400&auto=format&fit=crop&q=80',
      currentBid: 285,
      startingBid: 180,
      totalBids: 9,
      remainingTime: Duration(minutes: 18, seconds: 30),
      condition: 'Excellent',
      location: 'Borrowdale',
      isVerified: true,
    ),
  ];

  static final List<String> zimbabweLocations = [
    'Harare Central, ZW',
    'Avondale, Harare',
    'Borrowdale, Harare',
    'Eastlea, Harare',
    'Mount Pleasant, Harare',
    'Belvedere, Harare',
    'Bulawayo Central, ZW',
    'Gweru, ZW',
    'Mutare, ZW',
  ];
}
