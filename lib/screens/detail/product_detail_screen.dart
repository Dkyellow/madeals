import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/map_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/listing_item.dart';
import '../../providers/listings_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/network_image_fallback.dart';
import '../../widgets/common/verified_badge.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String listingId;

  const ProductDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp(ListingItem item) async {
    final cleanPhone = item.sellerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Hi ${item.sellerName}, I am interested in your listing "${item.title}" on MADEALS for ${item.formattedPrice}. Is it still available to inspect in ${item.location}?',
    );
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showContactFallbackDialog(item, 'WhatsApp: $url');
      }
    } catch (_) {
      if (mounted) {
        _showContactFallbackDialog(item, 'WhatsApp: https://wa.me/$cleanPhone');
      }
    }
  }

  Future<void> _launchPhoneCall(ListingItem item) async {
    final cleanPhone = item.sellerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:$cleanPhone');

    try {
      final launched = await launchUrl(url);
      if (!launched && mounted) {
        _showContactFallbackDialog(item, 'Phone: ${item.sellerPhone}');
      }
    } catch (_) {
      if (mounted) {
        _showContactFallbackDialog(item, 'Phone: ${item.sellerPhone}');
      }
    }
  }

  void _showContactFallbackDialog(ListingItem item, String contactInfo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contact ${item.sellerName}'),
        content: Text(
          'Direct contact details:\n\n$contactInfo\nSeller Phone: ${item.sellerPhone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTradeProposalModal(BuildContext context, ListingItem item) {
    final tradeItemController = TextEditingController();
    final cashTopUpController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
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
                children: [
                  const Icon(Icons.swap_horizontal_circle_rounded, color: AppColors.zimGreen, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Propose P2P Trade Swap',
                    style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Trading for: ${item.title} (${item.formattedPrice})',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tradeItemController,
                decoration: const InputDecoration(
                  labelText: 'What item are you offering in exchange?',
                  hintText: 'e.g. 2012 Toyota Vitz + iPhone 12',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cashTopUpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cash adjustment/top-up (USD \$)',
                  hintText: 'e.g. 400 (Optional)',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final offered = tradeItemController.text.trim().isNotEmpty
                      ? tradeItemController.text.trim()
                      : 'Trade Offer Item';
                  final cash = cashTopUpController.text.trim().isNotEmpty
                      ? ' + \$${cashTopUpController.text.trim()} cash'
                      : '';

                  // Add trade proposition into in-app chat with seller
                  ref.read(chatProvider.notifier).startOrGetThread(
                        listingId: item.id,
                        sellerName: item.sellerName,
                        sellerPhone: item.sellerPhone,
                        sellerAvatar: item.sellerAvatar ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                        listingTitle: item.title,
                        listingPrice: item.formattedPrice,
                        listingImage: item.firstImage,
                        initialMessage: '🤝 [TRADE PROPOSAL]: Offering $offered$cash in exchange for ${item.title}.',
                      );

                  Navigator.pop(modalContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.zimGreen,
                      content: Text('Trade proposal sent to ${item.sellerName}! Check Messages tab.'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Submit Trade Proposal',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startInAppChat(ListingItem item) {
    ref.read(chatProvider.notifier).startOrGetThread(
          listingId: item.id,
          sellerName: item.sellerName,
          sellerPhone: item.sellerPhone,
          sellerAvatar: item.sellerAvatar ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          listingTitle: item.title,
          listingPrice: item.formattedPrice,
          listingImage: item.firstImage,
        );
    context.push('/messages');
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(singleListingProvider(widget.listingId)) ??
        ref.watch(listingsProvider).first;

    final isBookmarked = item.isBookmarked;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Item Details',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share link: madeals.co.zw/d/${item.id}'),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isBookmarked ? AppColors.error : AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () {
              ref.read(listingsProvider.notifier).toggleBookmark(item.id);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media Section: Image Carousel with Pagination Indicator
                    _buildImageCarousel(item),
                    // Product Meta & Price Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price & Negotiable Badge Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                item.formattedPrice,
                                style: AppTextStyles.priceLarge.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (item.isNegotiable)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'Negotiable',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Title
                          Text(
                            item.title,
                            style: AppTextStyles.headlineLarge.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Location, distance, time listed
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${item.location} · ${item.formattedDistance} away · Listed ${item.timeListedAgo}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          // Seller Profile Card
                          _buildSellerCard(item),
                          const SizedBox(height: 20),
                          // Feature Grid Specs (2x2)
                          Text(
                            'SPECIFICATIONS',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSpecsGrid(item),
                          const SizedBox(height: 20),
                          // Description
                          Text(
                            'DESCRIPTION',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Barter Offer Box (if applicable)
                          if (item.allowsBarter) ...[
                            _buildBarterOfferBox(item),
                            const SizedBox(height: 20),
                          ],
                          // Location / Meetup Spot Preview
                          Text(
                            'SAFE MEETUP SPOT',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildMeetupLocationCard(item),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Fixed Action Bar with Real Call, WhatsApp & Chat
            _buildBottomActionBar(item),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(ListingItem item) {
    final images = item.images.isNotEmpty ? item.images : [item.firstImage];

    return SizedBox(
      height: 270,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return SafeNetworkImage(
                imageUrl: images[index],
                height: 270,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            },
          ),
          // Gradient shadow overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Pagination Indicator (1/4 indicator)
          Positioned(
            bottom: 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Verified Pill Overlay
          if (item.isVerified)
            Positioned(
              top: 14,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Zimbabwe Listing',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(ListingItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SafeNetworkImage(
            imageUrl: item.sellerAvatar ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.sellerName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const VerifiedBadge(size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      '${item.sellerRating} ★',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' · ${item.sellerReviewsCount} reviews',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
            tooltip: 'Call Seller',
            onPressed: () => _launchPhoneCall(item),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid(ListingItem item) {
    final entries = item.specs.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.key.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.value,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarterOfferBox(ListingItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.zimGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'OPEN TO SWAPS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.swap_horiz_rounded, color: AppColors.zimYellow, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Seller accepts trade-ins or partial barter',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.tradeDetails != null) ...[
            const SizedBox(height: 4),
            Text(
              item.tradeDetails!,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync_alt_rounded, size: 16, color: Colors.white),
              label: Text(
                'Propose Trade / Barter Swap',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () => _showTradeProposalModal(context, item),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetupLocationCard(ListingItem item) {
    final meetupLatLng = LatLng(item.latitude, item.longitude);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.meetupSpot,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Monitored public area with daylight lighting & security',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Meetup Location Mini-Map (free flutter_map / CartoDB light tiles)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: meetupLatLng,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(flags: 0),
                ),
                children: [
                  ColorFiltered(
                    colorFilter: MapTheme.appThemeFilter,
                    child: TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.madeals',
                    ),
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: meetupLatLng,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ListingItem item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // WhatsApp Launch Button
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_rounded, color: AppColors.whatsAppGreen, size: 18),
              label: Text(
                'WhatsApp',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () => _launchWhatsApp(item),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Direct In-App Message Seller Button
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              label: Text(
                'Message',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () => _startInAppChat(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
