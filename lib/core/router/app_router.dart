import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home/home_feed_screen.dart';
import '../../screens/search/search_discovery_screen.dart';
import '../../screens/detail/product_detail_screen.dart';
import '../../screens/sell/post_deal_screen.dart';
import '../../screens/messages/messages_screen.dart';
import '../../screens/messages/chat_room_screen.dart';
import '../../screens/profile/user_profile_screen.dart';
import '../../widgets/navigation/main_shell_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Soft push transition: quick fade + gentle slide-up (detail/sell/chat).
CustomTransitionPage<void> _softPush(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShellScaffold(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          // Home Feed (Open Marketplace root - No Auth required)
          GoRoute(
            path: '/',
            name: 'home-root',
            builder: (context, state) => const HomeFeedScreen(),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeFeedScreen(),
          ),
          // Search & Map Discovery
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchDiscoveryScreen(),
          ),
          // Item Detail
          GoRoute(
            path: '/item-detail/:id',
            name: 'item-detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? 'deal_01';
              return _softPush(state, ProductDetailScreen(listingId: id));
            },
          ),
          GoRoute(
            path: '/detail/:id',
            name: 'detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? 'deal_01';
              return _softPush(state, ProductDetailScreen(listingId: id));
            },
          ),
          // Sell / Post a Deal
          GoRoute(
            path: '/sell',
            name: 'sell',
            pageBuilder: (context, state) =>
                _softPush(state, const PostDealScreen()),
          ),
          GoRoute(
            path: '/post-deal',
            name: 'post-deal',
            pageBuilder: (context, state) =>
                _softPush(state, const PostDealScreen()),
          ),
          // Messages & Real-Time Chat Room
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/chat/:threadId',
            name: 'chat-room',
            pageBuilder: (context, state) {
              final threadId = state.pathParameters['threadId'] ?? 'thread_01';
              return _softPush(state, ChatRoomScreen(threadId: threadId));
            },
          ),
          // Guest Profile & Settings
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const UserProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
  );
}
