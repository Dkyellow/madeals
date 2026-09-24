class ChatMessage {
  final String id;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isFromMe;
  final String? tradeOfferSummary;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isFromMe,
    this.tradeOfferSummary,
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatThread {
  final String id;
  final String recipientName;
  final String recipientPhone;
  final String recipientAvatar;
  final String listingId;
  final String listingTitle;
  final String listingPrice;
  final String listingImage;
  final List<ChatMessage> messages;
  final bool isVerifiedSeller;

  const ChatThread({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.recipientAvatar,
    required this.listingId,
    required this.listingTitle,
    required this.listingPrice,
    required this.listingImage,
    required this.messages,
    this.isVerifiedSeller = true,
  });

  ChatMessage get lastMessage => messages.last;

  ChatThread copyWith({
    String? id,
    String? recipientName,
    String? recipientPhone,
    String? recipientAvatar,
    String? listingId,
    String? listingTitle,
    String? listingPrice,
    String? listingImage,
    List<ChatMessage>? messages,
    bool? isVerifiedSeller,
  }) {
    return ChatThread(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientAvatar: recipientAvatar ?? this.recipientAvatar,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingPrice: listingPrice ?? this.listingPrice,
      listingImage: listingImage ?? this.listingImage,
      messages: messages ?? this.messages,
      isVerifiedSeller: isVerifiedSeller ?? this.isVerifiedSeller,
    );
  }
}
