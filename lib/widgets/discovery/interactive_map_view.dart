import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/map_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/listing_item.dart';

/// Plain, Google-Maps-like discovery view centered on Harare CBD
/// (-17.8252, 31.0335) using Esri Light Gray Canvas tiles — uniform gray,
/// no green/beige landuse, no transit lines, street labels only.
/// with interactive price pins. Tapping a pin opens an in-map bottom sheet
/// previewing the listing.
class InteractiveMapView extends StatefulWidget {
  final List<ListingItem> listings;
  final ValueChanged<ListingItem> onPinSelected;

  /// Map height. Null = fill the parent (full-screen background mode).
  final double? height;

  /// Rounded card look; false = full-bleed background (no radius/border).
  final bool rounded;

  const InteractiveMapView({
    super.key,
    required this.listings,
    required this.onPinSelected,
    this.height = 240,
    this.rounded = true,
  });

  @override
  State<InteractiveMapView> createState() => _InteractiveMapViewState();
}

class _InteractiveMapViewState extends State<InteractiveMapView> {
  static const LatLng _harareCbd = LatLng(-17.8252, 31.0335);
  static const double _userZoom = 14;

  final MapController _mapController = MapController();

  String? selectedListingId;
  bool _focusedOnUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnUserLocation());
  }

  /// Open the map centered on the device location (falls back to Harare CBD).
  Future<void> _focusOnUserLocation() async {
    if (_focusedOnUser || !mounted) return;
    _focusedOnUser = true;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      ).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _userZoom,
      );
    } catch (_) {
      // Timeout / service disabled — keep the Harare CBD default.
    }
  }

  void _onPinTapped(ListingItem item) {
    setState(() => selectedListingId = item.id);
    _showListingPreviewSheet(item);
  }

  void _showListingPreviewSheet(ListingItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.firstImage,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.formattedPrice,
                        style: AppTextStyles.priceMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.location} · ${item.formattedDistance}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onPinSelected(item);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 46),
                ),
                child: Text(
                  'View Deal',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
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

  Widget _buildPricePin(ListingItem item) {
    final isSelected = selectedListingId == item.id;

    return GestureDetector(
      onTap: () => _onPinTapped(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.zimGreen : AppColors.primary,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sell_outlined, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    item.formattedPrice,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pointer tail
          CustomPaint(
            size: const Size(12, 6),
            painter: _PinTailPainter(
              color: isSelected ? AppColors.zimGreen : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(widget.rounded ? 16 : 0),
        border: widget.rounded
            ? Border.all(color: AppColors.border, width: 1)
            : null,
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _harareCbd,
              initialZoom: 12.5,
            ),
            children: [
              // Plain light-gray basemap (Esri) + street + place-label overlays.
              TileLayer(
                urlTemplate: MapTiles.urlTemplate,
                userAgentPackageName: 'com.madeals.app',
                maxNativeZoom: MapTiles.maxNativeZoom,
              ),
              if (MapTiles.showReferenceOverlay)
                TileLayer(
                  urlTemplate: MapTiles.referenceUrlTemplate,
                  userAgentPackageName: 'com.madeals.app',
                  maxNativeZoom: MapTiles.maxNativeZoom,
                ),
              if (MapTiles.showPlacesOverlay)
                TileLayer(
                  urlTemplate: MapTiles.placesUrlTemplate,
                  userAgentPackageName: 'com.madeals.app',
                  maxNativeZoom: MapTiles.maxNativeZoom,
                ),
              MarkerLayer(
                markers: widget.listings
                    .map(
                      (item) => Marker(
                        point: LatLng(item.latitude, item.longitude),
                        width: 90,
                        height: 46,
                        alignment: Alignment.topCenter,
                        child: _buildPricePin(item),
                      ),
                    )
                    .toList(),
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                popupInitialDisplayDuration: const Duration(seconds: 5),
                attributions: [
                  TextSourceAttribution(MapTiles.attribution),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_rounded,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Harare Interactive Discovery',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Tap a price pin to preview the deal',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white, fontSize: 9.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;

  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) =>
      oldDelegate.color != color;
}
