class AuctionItem {
  final String id;
  final String title;
  final String imageUrl;
  final double currentBid;
  final double startingBid;
  final int totalBids;
  final Duration remainingTime;
  final String condition;
  final String location;
  final bool isVerified;

  const AuctionItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.currentBid,
    required this.startingBid,
    required this.totalBids,
    required this.remainingTime,
    required this.condition,
    required this.location,
    this.isVerified = true,
  });
}
