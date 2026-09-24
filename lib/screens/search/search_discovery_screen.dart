import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/auction_item.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/discovery/live_auction_banner.dart';
import '../../widgets/discovery/interactive_map_view.dart';
import '../../widgets/listing/compact_listing_card.dart';

class SearchDiscoveryScreen extends ConsumerStatefulWidget {
  const SearchDiscoveryScreen({super.key});

  @override
  ConsumerState<SearchDiscoveryScreen> createState() => _SearchDiscoveryScreenState();
}

class _SearchDiscoveryScreenState extends ConsumerState<SearchDiscoveryScreen> {
  late TextEditingController _searchController;
  AuctionItem _mockAuction = const AuctionItem(
    id: 'auc_01',
    title: 'iPhone 13 128GB Unlocked (Harare CBD)',
    imageUrl: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=400',
    currentBid: 340,
    startingBid: 250,
    totalBids: 14,
    remainingTime: Duration(minutes: 1, seconds: 42),
    condition: '9/10 Battery 88%',
    location: 'Harare CBD',
    isVerified: true,
  );

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
                        style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(selectedMaxPriceProvider.notifier).state = null;
                          ref.read(selectedDistanceFilterProvider.notifier).state = null;
                          ref.read(isVerifiedOnlyProvider.notifier).state = false;
                          ref.read(selectedCategoryProvider.notifier).state = 'All';
                          ref.read(searchQueryProvider.notifier).state = '';
                          _searchController.clear();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Reset All',
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Max Price: \$${currentMaxPrice.toInt()}',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
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
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
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
                      ref.read(selectedMaxPriceProvider.notifier).state = currentMaxPrice;
                      ref.read(selectedDistanceFilterProvider.notifier).state = currentDistance;
                      ref.read(isVerifiedOnlyProvider.notifier).state = verifiedOnly;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
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

  void _showBidBottomSheet(BuildContext context) {
    double nextBid = _mockAuction.currentBid + 10;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Place Instant Bid',
                style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Next minimum bid is \$${nextBid.toInt()}. Peer-to-peer settlement upon auction close.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _mockAuction = AuctionItem(
                      id: _mockAuction.id,
                      title: _mockAuction.title,
                      imageUrl: _mockAuction.imageUrl,
                      currentBid: nextBid,
                      startingBid: _mockAuction.startingBid,
                      totalBids: _mockAuction.totalBids + 1,
                      remainingTime: _mockAuction.remainingTime + const Duration(seconds: 45),
                      condition: _mockAuction.condition,
                      location: _mockAuction.location,
                      isVerified: true,
                    );
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.zimGreen,
                      content: Text('🎉 Bid placed for \$${nextBid.toInt()}! You are currently the highest bidder.'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Confirm Bid: \$${nextBid.toInt()}',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: _buildSearchInputField(),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: Icon(
              isMapView ? Icons.view_list_rounded : Icons.map_rounded,
              color: AppColors.primary,
            ),
            tooltip: isMapView ? 'Switch to List' : 'Switch to Map',
            onPressed: () {
              ref.read(isMapViewProvider.notifier).state = !isMapView;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Applied Filter Tags Bar
            _buildAppliedFiltersRow(
              query: query,
              category: selectedCategory,
              maxPrice: maxPrice,
              distance: distance,
            ),
            const Divider(height: 1),
            // Results & Discovery Scroll Area
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Live Auction Banner
                  LiveAuctionBanner(
                    auction: _mockAuction,
                    onBidTap: () => _showBidBottomSheet(context),
                  ),
                  const SizedBox(height: 16),

                  // Interactive Map View Header
                  if (isMapView) ...[
                    InteractiveMapView(
                      listings: searchResults,
                      onPinSelected: (item) {
                        context.push('/item-detail/${item.id}');
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Results count & Sort
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${searchResults.length} listings in Harare',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.sort_rounded, size: 16, color: AppColors.textSecondary),
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
                  ),
                  const SizedBox(height: 12),

                  // Compact Cards List
                  if (searchResults.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No exact matches for current search',
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try resetting filters or expanding price limit.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    )
                  else
                    ...searchResults.map((item) {
                      return CompactListingCard(
                        item: item,
                        onTap: () {
                          context.push('/item-detail/${item.id}');
                        },
                        onBookmarkToggle: () {
                          ref.read(listingsProvider.notifier).toggleBookmark(item.id);
                        },
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInputField() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search Zimbabwe deals...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (val) {
          ref.read(searchQueryProvider.notifier).state = val;
        },
      ),
    );
  }

  Widget _buildAppliedFiltersRow({
    required String query,
    required String category,
    required double? maxPrice,
    required double? distance,
  }) {
    final List<Widget> filterPills = [];

    // Filter Button
    filterPills.add(
      GestureDetector(
        onTap: _showFilterModal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
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

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filterPills
              .map((w) => Padding(padding: const EdgeInsets.only(right: 6), child: w))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterTag(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
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
            child: const Icon(Icons.close_rounded, size: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
