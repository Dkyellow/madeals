import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/verification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/app_logo.dart';

class SecurityChecklistScreen extends ConsumerWidget {
  const SecurityChecklistScreen({super.key});

  void _showIdUploadModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Upload National ID or Passport',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Take a clear photo of your metal ID, plastic ID, or Zimbabwean passport bio page.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Option 1: Camera
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 28),
                title: Text(
                  'Take Photo with Camera',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Fastest method · Automatic glare detection',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.pop(modalContext);
                  ref.read(verificationProvider.notifier).completeIdUpload('mock_id_card.jpg');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.zimGreen,
                      content: Text('ID uploaded! Trust Score updated to 82%. Complete selfie next.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Option 2: Gallery
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 28),
                title: Text(
                  'Choose from Photo Gallery',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'JPEG, PNG or PDF document (max 5MB)',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.pop(modalContext);
                  ref.read(verificationProvider.notifier).completeIdUpload('mock_passport.jpg');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.zimGreen,
                      content: Text('Passport bio page submitted for review.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verification = ref.watch(verificationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const AppLogo(fontSize: 20),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Verification & Security',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Verify your identity to unlock high-trust badges, instant buyer messaging, and unlimited listings.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Trust Score Banner
                    _buildTrustScoreBanner(verification.trustScore),
                    const SizedBox(height: 24),
                    // Checklist Section
                    Text(
                      'VERIFICATION CHECKLIST',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 1. Phone Confirmed (Done)
                    _buildChecklistItem(
                      index: '1',
                      title: 'Phone Confirmed',
                      subtitle: '+263 77 412 8990 (EcoCash verified)',
                      status: _ItemStatus.done,
                    ),
                    const SizedBox(height: 12),
                    // 2. National ID / Passport
                    _buildChecklistItem(
                      index: '2',
                      title: 'National ID / Passport',
                      subtitle: verification.idState == IdVerificationState.pendingReview
                          ? 'Uploaded · Pending instant OCR review'
                          : 'Government issued Zimbabwe ID or Passport',
                      status: verification.idState == IdVerificationState.pendingReview
                          ? _ItemStatus.pending
                          : (verification.idState == IdVerificationState.verified
                              ? _ItemStatus.done
                              : _ItemStatus.ready),
                    ),
                    const SizedBox(height: 12),
                    // 3. Selfie Match
                    _buildChecklistItem(
                      index: '3',
                      title: 'Selfie Match',
                      subtitle: verification.selfieState == SelfieVerificationState.locked
                          ? 'Unlocks after uploading National ID'
                          : (verification.selfieState == SelfieVerificationState.verified
                              ? 'Liveness check verified 100%'
                              : 'Ready for quick 5-second face scan'),
                      status: verification.selfieState == SelfieVerificationState.locked
                          ? _ItemStatus.locked
                          : (verification.selfieState == SelfieVerificationState.verified
                              ? _ItemStatus.done
                              : _ItemStatus.ready),
                      onTap: verification.selfieState == SelfieVerificationState.inProgress
                          ? () {
                              ref.read(verificationProvider.notifier).completeSelfieVerification();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.zimGreen,
                                  content: Text('Awesome! Fully verified. Community Trust Score 98%.'),
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 24),
                    // Privacy Disclaimer
                    _buildPrivacyNotice(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Bottom Actions Area
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomButton(
                    text: verification.selfieState == SelfieVerificationState.inProgress
                        ? 'Perform 5-Second Selfie Scan'
                        : 'Upload National ID / Passport',
                    leadingIcon: Icon(
                      verification.selfieState == SelfieVerificationState.inProgress
                          ? Icons.face_rounded
                          : Icons.badge_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      if (verification.selfieState == SelfieVerificationState.inProgress) {
                        ref.read(verificationProvider.notifier).completeSelfieVerification();
                      } else {
                        _showIdUploadModal(context, ref);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).continueAsGuest();
                      context.go('/home');
                    },
                    child: Text(
                      'Continue as Guest (Browsing Only)',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustScoreBanner(int score) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Circular Trust Score Meter
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    score >= 90 ? AppColors.zimGreen : (score >= 70 ? AppColors.primary : AppColors.warning),
                  ),
                ),
              ),
              Text(
                '$score%',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Community Trust Score',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  score >= 90
                      ? 'Tier 1 Verified Trader · Eligible for Instant WhatsApp Leads'
                      : 'Complete remaining steps to achieve full Tier 1 Verified status.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String index,
    required String title,
    required String subtitle,
    required _ItemStatus status,
    VoidCallback? onTap,
  }) {
    Color borderColor;
    Color iconBg;
    Widget statusWidget;

    switch (status) {
      case _ItemStatus.done:
        borderColor = AppColors.success.withValues(alpha: 0.4);
        iconBg = const Color(0xFFD1FAE5);
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
              const SizedBox(width: 4),
              Text(
                'DONE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
        break;
      case _ItemStatus.pending:
        borderColor = AppColors.warning.withValues(alpha: 0.5);
        iconBg = const Color(0xFFFEF3C7);
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 14),
              const SizedBox(width: 4),
              Text(
                'REVIEW',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
        break;
      case _ItemStatus.ready:
        borderColor = AppColors.primary.withValues(alpha: 0.3);
        iconBg = AppColors.primaryLight;
        statusWidget = const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14);
        break;
      case _ItemStatus.locked:
        borderColor = AppColors.border;
        iconBg = AppColors.surfaceVariant;
        statusWidget = const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 16);
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  index,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: status == _ItemStatus.done
                        ? AppColors.success
                        : (status == _ItemStatus.locked ? AppColors.textMuted : AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            statusWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strict Privacy & Data Protection',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your government ID and biometric data are encrypted with 256-bit AES standards and never shared with other marketplace users.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontSize: 11.5,
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

enum _ItemStatus { done, pending, ready, locked }
