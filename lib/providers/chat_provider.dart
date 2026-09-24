import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class ChatNotifier extends StateNotifier<List<ChatThread>> {
  ChatNotifier() : super(_initialThreads());

  static List<ChatThread> _initialThreads() {
    return [
      ChatThread(
        id: 'thread_01',
        recipientName: 'Tendai M.',
        recipientPhone: '+263771234567',
        recipientAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        listingId: 'deal_01',
        listingTitle: '2016 Toyota Axio 1.5 Hybrid',
        listingPrice: '\$4,800',
        listingImage: 'https://images.unsplash.com/photo-1590362891991-f776e747a588?w=300',
        messages: [
          ChatMessage(
            id: 'm1',
            senderName: 'You',
            text: 'Hi Tendai, is the Axio Hybrid still available for inspection in Harare CBD?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            isFromMe: true,
          ),
          ChatMessage(
            id: 'm2',
            senderName: 'Tendai M.',
            text: 'Yes! We can meet at Meikles Hotel reception area at 2pm tomorrow for inspection.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
            isFromMe: false,
          ),
        ],
      ),
      ChatThread(
        id: 'thread_02',
        recipientName: 'Kudakwashe Z.',
        recipientPhone: '+263719876543',
        recipientAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        listingId: 'deal_02',
        listingTitle: 'iPhone 13 · 128GB Midnight',
        listingPrice: '\$380',
        listingImage: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=300',
        messages: [
          ChatMessage(
            id: 'm3',
            senderName: 'Kudakwashe Z.',
            text: 'Hello, battery health is 89%, never opened or repaired. Cash or EcoCash accepted.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            isFromMe: false,
          ),
        ],
      ),
    ];
  }

  void sendMessage(String threadId, String text) {
    const uuid = Uuid();
    final newMessage = ChatMessage(
      id: uuid.v4(),
      senderName: 'You',
      text: text,
      timestamp: DateTime.now(),
      isFromMe: true,
    );

    state = state.map((thread) {
      if (thread.id == threadId) {
        return thread.copyWith(messages: [...thread.messages, newMessage]);
      }
      return thread;
    }).toList();
  }

  void startOrGetThread({
    required String listingId,
    required String sellerName,
    required String sellerPhone,
    required String sellerAvatar,
    required String listingTitle,
    required String listingPrice,
    required String listingImage,
    String? initialMessage,
  }) {
    final existingIndex = state.indexWhere((t) => t.listingId == listingId);
    const uuid = Uuid();

    if (existingIndex == -1) {
      final newThread = ChatThread(
        id: 'thread_${uuid.v4().substring(0, 8)}',
        recipientName: sellerName,
        recipientPhone: sellerPhone,
        recipientAvatar: sellerAvatar,
        listingId: listingId,
        listingTitle: listingTitle,
        listingPrice: listingPrice,
        listingImage: listingImage,
        messages: [
          if (initialMessage != null)
            ChatMessage(
              id: uuid.v4(),
              senderName: 'You',
              text: initialMessage,
              timestamp: DateTime.now(),
              isFromMe: true,
            ),
        ],
      );
      state = [newThread, ...state];
    } else if (initialMessage != null) {
      sendMessage(state[existingIndex].id, initialMessage);
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatThread>>((ref) {
  return ChatNotifier();
});
