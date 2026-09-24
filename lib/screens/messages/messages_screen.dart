import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/network_image_fallback.dart';
import '../../widgets/common/verified_badge.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Buyer & Seller Messages',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Safe Meetup Notice
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Direct peer chat. Meet in verified public daylight spots across Harare before payment.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: threads.isEmpty
                  ? Center(
                      child: Text(
                        'No active conversations yet.\nBrowse listings to contact sellers.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: threads.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 76),
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        final lastMsg = thread.messages.isNotEmpty ? thread.messages.last : null;

                        return InkWell(
                          onTap: () {
                            context.push('/chat/${thread.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SafeNetworkImage(
                                  imageUrl: thread.recipientAvatar,
                                  width: 50,
                                  height: 50,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                thread.recipientName,
                                                style: AppTextStyles.titleMedium.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (thread.isVerifiedSeller) ...[
                                                const SizedBox(width: 4),
                                                const VerifiedBadge(size: 13),
                                              ],
                                            ],
                                          ),
                                          if (lastMsg != null)
                                            Text(
                                              lastMsg.formattedTime,
                                              style: AppTextStyles.labelSmall.copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${thread.listingTitle} (${thread.listingPrice})',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMsg != null ? lastMsg.text : 'Start conversation',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
