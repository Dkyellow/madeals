import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/micro_interactions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/discovery/interactive_map_view.dart';
import '../../widgets/listing/compact_listing_card.dart';

class SearchDiscoveryScreen extends ConsumerStatefulWidget {
  const SearchDiscoveryScreen({super.key});

  @override
  ConsumerState<SearchDiscoveryScreen> createState() =>
      _SearchDiscoveryScreenState();
}

class _SearchDiscoveryScreenState extends ConsumerState<SearchDiscoveryScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        double currentMaxPrice = ref.watch(selectedMaxPriceProvider) ?? 2000;
        double currentDistance = ref.watch(selectedDistanceFilterProvider) ?? 15;
        bool verifiedOnly = ref.watch(isVerifiedOnlyProvider);

        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Listings',
                        style: AppTextStyles.headlineMedium
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(selectedMaxPriceProvider.notifier).state =
                              null;
                          ref.read(selectedDistanceFilterProvider.notifier)
                              .state = null;
                          ref.read(isVerifiedOnlyProvider.notifier).state =
                              false;
                          ref.read(selectedCategoryProvider.notifier).state =
                              'All';
                          ref.read(searchQueryProvider.notifier).state = '';
                          _searchController.clear();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Reset All',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Max Price: \$${currentMaxPrice.toInt()}',
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    value: currentMaxPrice,
                    min: 50,
                    max: 5000,
                    divisions: 99,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() {
                        currentMaxPrice = val;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Distance Radius: ${currentDistance.toInt()} km',
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    value: currentDistance,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() {
                        currentDistance = val;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Verified Zimbabwean Sellers Only',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Only display listings with verified badges',
                      style: AppTextStyles.bodySmall,
                    ),
                    value: verifiedOnly,
                    activeThumbColor: AppColors.zimGreen,
                    onChanged: (val) {
                      setModalState(() {
                        verifiedOnly = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(selectedMaxPriceProvider.notifier).state =
                          currentMaxPrice;
                      ref.read(selectedDistanceFilterProvider.notifier).state =
                          currentDistance;
                      ref.read(isVerifiedOnlyProvider.notifier).state =
                          verifiedOnly;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(filteredListingsProvider);
    final isMapView = ref.watch(isMapViewProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final query = ref.watch(searchQueryProvider);
    final maxPrice = ref.watch(selectedMaxPriceProvider);
    final distance = ref.watch(selectedDistanceFilterProvider);

    final header = _FloatingHeader(
      searchController: _searchController,
      isMapView: isMapView,
      onBack: () => context.pop(),
      onSearchChanged: (val) {
        ref.read(searchQueryProvider.notifier).state = val;
      },
      onToggleView: () {
        ref.read(isMapViewProvider.notifier).state = !isMapView;
      },
      onFilterTap: _showFilterModal,
      filterPills: _buildAppliedFiltersRow(
        query: query,
        category: selectedCategory,
        maxPrice: maxPrice,
        distance: distance,
      ),
    );

    if (isMapView) {
      // Google Maps–style layout: map as full-screen background with
      // floating search controls and a draggable results sheet.
      return Scaffold(
        body: Stack(
          children: [
            // Full-bleed map background
            Positioned.fill(
              child: InteractiveMapView(
                height: null,
                rounded: false,
                listings: searchResults,
                onPinSelected: (item) {
                  context.push('/item-detail/${item.id}');
                },
              ),
            ),
            // Floating search + filter pills
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(bottom: false, child: header),
            ),
            // Draggable results sheet (Google Maps style)
            Positioned.fill(
              child: DraggableScrollableSheet(
                initialChildSize: 0.32,
                minChildSize: 0.12,
                maxChildSize: 0.88,
                snap: true,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      children: [
                        // Drag handle
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
                        const SizedBox(height: 12),
                        _buildResultsHeader(searchResults.length),
                        const SizedBox(height: 12),
                        ..._buildResultCards(searchResults),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // List view (map toggled off)
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            header,
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _buildResultsHeader(searchResults.length),
                  const SizedBox(height: 12),
                  ..._buildResultCards(searchResults),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$count listings in Harare',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.sort_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Closest first',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildResultCards(List<dynamic> results) {
    if (results.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No exact matches for current search',
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Try resetting filters or expanding price limit.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ];
    }

    return results.asMap().entries.map((entry) {
      return FadeSlideIn(
        delay: FadeSlideIn.stagger(entry.key),
        child: CompactListingCard(
          item: entry.value,
          onTap: () {
            context.push('/item-detail/${entry.value.id}');
          },
          onBookmarkToggle: () {
            ref.read(listingsProvider.notifier).toggleBookmark(entry.value.id);
          },
        ),
      );
    }).toList();
  }

  Widget _buildAppliedFiltersRow({
    required String query,
    required String category,
    required double? maxPrice,
    required double? distance,
  }) {
    final List<Widget> filterPills = [];

    filterPills.add(
      GestureDetector(
        onTap: _showFilterModal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Filters',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (query.isNotEmpty) {
      filterPills.add(_buildFilterTag('Query: $query', () {
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).state = '';
      }));
    }

    if (category != 'All') {
      filterPills.add(_buildFilterTag(category, () {
        ref.read(selectedCategoryProvider.notifier).state = 'All';
      }));
    }

    if (maxPrice != null) {
      filterPills.add(_buildFilterTag('<\$${maxPrice.toInt()}', () {
        ref.read(selectedMaxPriceProvider.notifier).state = null;
      }));
    }

    if (distance != null) {
      filterPills.add(_buildFilterTag('<${distance.toInt()}km', () {
        ref.read(selectedDistanceFilterProvider.notifier).state = null;
      }));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filterPills
            .map((w) => Padding(padding: const EdgeInsets.only(right: 6), child: w))
            .toList(),
      ),
    );
  }

  Widget _buildFilterTag(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Floating Google Maps–style search card + filter pills overlay.
class _FloatingHeader extends StatelessWidget {
  final TextEditingController searchController;
  final bool isMapView;
  final VoidCallback onBack;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleView;
  final VoidCallback onFilterTap;
  final Widget filterPills;

  const _FloatingHeader({
    required this.searchController,
    required this.isMapView,
    required this.onBack,
    required this.onSearchChanged,
    required this.onToggleView,
    required this.onFilterTap,
    required this.filterPills,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: onBack,
                ),
                Expanded(child: _SearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                )),
                IconButton(
                  icon: Icon(
                    isMapView ? Icons.view_list_rounded : Icons.map_rounded,
                    color: AppColors.primary,
                  ),
                  tooltip: isMapView ? 'Switch to List' : 'Switch to Map',
                  onPressed: onToggleView,
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded,
                      color: AppColors.primary),
                  tooltip: 'Filters',
                  onPressed: onFilterTap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Floating filter pills
          Align(
            alignment: Alignment.centerLeft,
            child: filterPills,
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
        decoration: InputDecoration(
          hintText: 'Search Zimbabwe deals...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textMuted,
            fontSize: 13.5,
          ),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 17),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 15),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
