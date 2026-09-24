import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/step_progress_bar.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/verified_badge.dart';

class ValuePropDetailScreen extends StatelessWidget {
  const ValuePropDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const AppLogo(fontSize: 20),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(
              'Skip',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 24),
            onPressed: () => context.push('/phone-auth'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: StepProgressBar(
                currentStep: 3,
                totalSteps: 4,
                showStepText: true,
              ),
            ),
            const SizedBox(height: 12),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deal directly.\nNo middlemen.',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buy, sell, and barter in local currency or USD with zero broker interference and direct settlement.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Highlighted Protocol Card
                    _buildHighlightedProtocolCard(),
                    const SizedBox(height: 20),
                    // 4 Feature Cards (Icon + Title + Subtext)
                    _buildFeatureCard(
                      icon: Icons.chat_outlined,
                      iconColor: AppColors.primary,
                      title: 'Direct Chat & WhatsApp',
                      subtext: 'Contact sellers directly through one-click WhatsApp messaging or free in-app chat with real-time delivery.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.storefront_outlined,
                      iconColor: AppColors.zimGreen,
                      title: 'Public Meetups & Inspection',
                      subtext: 'Meet in safe designated public spots (e.g. Sam Levy Village, Meikles, Avondale) to test items before payment.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFFD97706),
                      title: '100% Cash or Peer Transfer',
                      subtext: 'Pay via EcoCash, Innbucks, Zipit, USD Cash, or Barter swap. No funds held in escrow by third parties.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.verified_user_outlined,
                      iconColor: AppColors.zimGreen,
                      title: 'Verified Zimbabwean Sellers',
                      subtext: 'Trust badges for sellers who have verified their Zimbabwean National ID, phone number, and facial identity.',
                      trailingBadge: const VerifiedBadge(showLabel: true, label: 'Verified ID'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: CustomButton(
                text: 'Continue',
                trailingIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  context.push('/phone-auth');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedProtocolCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                ),
                child: Text(
                  'P2P VERIFIED PROTOCOL',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF60A5FA),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.zimGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '0% COMMISSION',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF34D399),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Keep 100% of Every Transaction',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unlike traditional classifieds or overseas apps, MADEALS charges zero transaction fees on all peer-to-peer listings.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtext,
    Widget? trailingBadge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    ?trailingBadge,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtext,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
