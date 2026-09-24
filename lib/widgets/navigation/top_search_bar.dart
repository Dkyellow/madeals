import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/app_logo.dart';

class TopSearchBar extends StatelessWidget {
  final String location;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  /// Real-time search: typed text is pushed through [onSearchChanged]
  /// so the feed can re-query the local SQLite-backed listings.
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  const TopSearchBar({
    super.key,
    required this.location,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onSearchTap,
    required this.onFilterTap,
    this.searchController,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // Top Row: Logo, Location picker, Notifications
          Row(
            children: [
              const AppLogo(fontSize: 19),
              const Spacer(),
              // Location Dropdown button
              GestureDetector(
                onTap: onLocationTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Notification Bell
              GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search Bar Input Field (real-time local query when wired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: searchController != null
                      ? TextField(
                          controller: searchController,
                          textInputAction: TextInputAction.search,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search vehicles, phones, services...',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 13.5,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: onSearchChanged,
                        )
                      : GestureDetector(
                          onTap: onSearchTap,
                          child: Text(
                            'Search vehicles, phones, services...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                ),
                if (searchController != null &&
                    searchController!.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      searchController!.clear();
                      onSearchChanged?.call('');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  )
                else ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onFilterTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
