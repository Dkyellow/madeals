import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav_bar.dart';

class MainShellScaffold extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShellScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  int _calculateSelectedIndex() {
    if (location.startsWith('/search')) {
      return 1;
    }
    if (location.startsWith('/messages') || location.startsWith('/chat')) {
      return 2;
    }
    if (location.startsWith('/profile')) {
      return 3;
    }
    // Default to Home (Tab 0) for /, /home, /item-detail, etc.
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _calculateSelectedIndex(),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/search');
              break;
            case 2:
              context.go('/messages');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        onSellTap: () {
          context.push('/sell');
        },
      ),
    );
  }
}
