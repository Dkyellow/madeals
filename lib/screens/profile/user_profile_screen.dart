import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/common/network_image_fallback.dart';
import '../../widgets/common/verified_badge.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(listingsProvider);
    final bookmarkedCount = listings.where((l) => l.isBookmarked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Guest Profile & Trust Status',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // User Card Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SafeNetworkImage(
                      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                      width: 76,
                      height: 76,
                      borderRadius: BorderRadius.all(Radius.circular(38)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Zimbabwe Guest Trader',
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const VerifiedBadge(size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Open Access · No Login Required',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.zimGreen, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Harare, Zimbabwe · P2P Direct Mode Active',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Trust Score', '98%', AppColors.primary),
                        _buildStatDivider(),
                        _buildStatColumn('Saved Items', '$bookmarkedCount', AppColors.zimGreen),
                        _buildStatDivider(),
                        _buildStatColumn('Commission', '0%', AppColors.warning),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trust & Safe Trading Protocol Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'P2P VERIFIED PROTOCOL',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFF60A5FA),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.zimGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '100% DIRECT',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: const Color(0xFF34D399),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Direct peer-to-peer contact via WhatsApp, phone calls, or in-app chat. Zero intermediary fees.',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Settings List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.favorite_border_rounded, color: AppColors.primary),
                      title: Text('Saved Favorites ($bookmarkedCount)', style: AppTextStyles.titleMedium),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/home'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.zimGreen),
                      title: Text('Payment Modes (EcoCash, Cash, Innbucks, Zipit)', style: AppTextStyles.titleMedium),
                      subtitle: const Text('Direct peer settlement accepted'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accepted: EcoCash, USD Cash, Innbucks, Zipit, and Barter.')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.location_city_rounded, color: AppColors.primary),
                      title: Text('Active Region: Harare Metro & Across ZW', style: AppTextStyles.titleMedium),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/search'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.priceMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.border,
    );
  }
}
