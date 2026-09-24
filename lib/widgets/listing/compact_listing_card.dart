import 'package:flutter/material.dart';
import '../../core/animations/micro_interactions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/listing_item.dart';
import '../common/network_image_fallback.dart';
import '../common/verified_badge.dart';

class CompactListingCard extends StatelessWidget {
  final ListingItem item;
  final VoidCallback onTap;
  final VoidCallback onBookmarkToggle;

  const CompactListingCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      haptic: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                Hero(
                  tag: 'listing-image-${item.id}',
                  child: SafeNetworkImage(
                    imageUrl: item.firstImage,
                    width: 100,
                    height: 100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                if (item.allowsBarter)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.zimGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SWAP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onBookmarkToggle,
                        child: PopOnChanged(
                          value: item.isBookmarked,
                          child: Icon(
                            item.isBookmarked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: item.isBookmarked
                                ? AppColors.error
                                : AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Condition / Battery tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...item.tags.take(2),
                      if (item.specs.containsKey('Condition')) item.specs['Condition']!,
                    ].take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.formattedPrice,
                        style: AppTextStyles.priceMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item.location.split(',').first} · ${item.formattedDistance}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (item.isVerified) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(size: 12),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
