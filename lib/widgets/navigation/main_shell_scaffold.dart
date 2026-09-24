import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
    final onSellScreen =
        location.startsWith('/sell') || location.startsWith('/post-deal');

    return Scaffold(
      body: child,
      // Floating "Sell" action button (replaces the old nav-bar pill)
      floatingActionButton: onSellScreen
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                context.push('/sell');
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(
                'Sell',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
      ),
    );
  }
}
