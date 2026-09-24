import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/micro_interactions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/listing_item.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/common/shimmer.dart';
import '../../widgets/navigation/top_search_bar.dart';
import '../../widgets/listing/category_chip.dart';
import '../../widgets/listing/featured_listing_card.dart';
import '../../widgets/listing/listing_card.dart';
import '../../widgets/listing/barter_offer_card.dart';
import '../../models/trade_offer.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final List<String> _categories = [
    'All',
    'Vehicles',
    'Phones',
    'Electronics',
    'Solar & Power',
    'Property',
  ];

  late final TextEditingController _searchController;

  String _currentLocation = 'Harare, ZW';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
    // Load SQLite listings after first frame → shimmer skeletons show first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootListings());
  }

  Future<void> _bootListings() async {
    if (!mounted) return;
    if (ref.read(listingsProvider).isNotEmpty) {
      ref.read(bootCompletedProvider.notifier).state = true;
      return;
    }
    try {
      await ref.read(listingsProvider.notifier).refreshFromDb();
    } catch (_) {
      // DB unavailable (e.g. tests) — fall through and finish boot anyway.
    }
    if (mounted) {
      ref.read(bootCompletedProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLocationPicker() {
    final locations = [
      'Harare, ZW',
      'Avondale, Harare',
      'Borrowdale, Harare',
      'Eastlea, Harare',
      'Belvedere, Harare',
      'Bulawayo Central, ZW',
      'Mutare, ZW',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              Text(
                'Select Your Zimbabwe Location',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...locations.map((loc) {
                final isSelected = _currentLocation == loc;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    loc,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _currentLocation = loc;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(
          '🔔 You have 2 new buyer inquiries and 1 price drop in Harare.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredListings = ref.watch(filteredListingsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final booted = ref.watch(bootCompletedProvider);

    ListingItem? featuredItem;
    try {
      featuredItem = filteredListings.firstWhere((item) => item.isFeatured);
    } catch (_) {
      featuredItem = filteredListings.isNotEmpty
          ? filteredListings.first
          : null;
    }

    final otherListings = filteredListings
        .where((item) => item.id != featuredItem?.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search & Brand Bar
            TopSearchBar(
              location: _currentLocation,
              onLocationTap: _showLocationPicker,
              onNotificationTap: _showNotificationSnackbar,
              onSearchTap: () => context.push('/search'),
              onFilterTap: () => context.push('/search'),
              searchController: _searchController,
              onSearchChanged: (val) {
                ref.read(searchQueryProvider.notifier).state = val;
              },
            ),
            // Horizontal Category Chips Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((category) {
                    final isSelected =
                        selectedCategory.toLowerCase() ==
                        category.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        category: category,
                        isSelected: isSelected,
                        onSelected: (cat) {
                          ref.read(selectedCategoryProvider.notifier).state =
                              cat;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Main Feed Scrollable Area
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref.read(listingsProvider.notifier).refreshFromDb();
                },
                child: !booted
                    ? ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: const [HomeFeedSkeleton()],
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          // Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Nearby in ${_currentLocation.split(',').first}',
                                    style: AppTextStyles.headlineMedium
                                        .copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.zimGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Updated 2m ago',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Featured Listing Banner
                          if (featuredItem != null) ...[
                            FadeSlideIn(
                              child: FeaturedListingCard(
                                item: featuredItem,
                                onTap: () {
                                  context.push(
                                    '/item-detail/${featuredItem!.id}',
                                  );
                                },
                                onBookmarkToggle: () {
                                  ref
                                      .read(listingsProvider.notifier)
                                      .toggleBookmark(featuredItem!.id);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Barter Request Box
                          BarterOfferCard(
                            offer: const TradeOffer(
                              id: 't1',
                              offeredItem: 'M1 MacBook Air 8GB/256GB',
                              requestedItem:
                                  'iPad Pro 11" (M1/M2) + \$150 Cash',
                              userLocation: 'Mount Pleasant, Harare',
                              timeAgo: '12m ago',
                            ),
                            onTap: () {
                              context.push('/search');
                            },
                          ),
                          const SizedBox(height: 16),

                          // Section: Fresh Deals Masonry/Grid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Direct P2P Deals',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/search'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'View All',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Two-Column Grid with In-feed Post a Deal CTA
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: otherListings.length + 1,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.76,
                                ),
                            itemBuilder: (context, index) {
                              if (index == 1) {
                                return _buildInFeedSellCTA(context);
                              }

                              final itemIndex = index > 1 ? index - 1 : index;
                              if (itemIndex >= otherListings.length) {
                                return const SizedBox.shrink();
                              }

                              final listing = otherListings[itemIndex];
                              return FadeSlideIn(
                                delay: FadeSlideIn.stagger(
                                  itemIndex,
                                  stepMs: 45,
                                ),
                                child: ListingCard(
                                  item: listing,
                                  onTap: () {
                                    context.push('/item-detail/${listing.id}');
                                  },
                                  onBookmarkToggle: () {
                                    ref
                                        .read(listingsProvider.notifier)
                                        .toggleBookmark(listing.id);
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInFeedSellCTA(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/sell'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post a Deal',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Free to list in Harare · 0% commission',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'List Now ->',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
