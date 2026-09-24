class TradeOffer {
  final String id;
  final String offeredItem;
  final String requestedItem;
  final double? cashAdjustment;
  final String userLocation;
  final String timeAgo;
  final bool isUrgent;

  const TradeOffer({
    required this.id,
    required this.offeredItem,
    required this.requestedItem,
    this.cashAdjustment,
    required this.userLocation,
    required this.timeAgo,
    this.isUrgent = false,
  });
}
