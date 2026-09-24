import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/google_map_style.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/listing_item.dart';

/// Google Maps discovery view centered on Harare CBD (-17.8252, 31.0335)
/// with custom light-silver JSON styling and interactive price pins.
/// Tapping a pin opens an in-map bottom sheet previewing the listing.
class InteractiveMapView extends StatefulWidget {
  final List<ListingItem> listings;
  final ValueChanged<ListingItem> onPinSelected;

  const InteractiveMapView({
    super.key,
    required this.listings,
    required this.onPinSelected,
  });

  @override
  State<InteractiveMapView> createState() => _InteractiveMapViewState();
}

class _InteractiveMapViewState extends State<InteractiveMapView> {
  static const LatLng _harareCbd = LatLng(-17.8252, 31.0335);

  GoogleMapController? _mapController;
  String? selectedListingId;
  Map<String, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(covariant InteractiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listings != widget.listings) {
      _buildMarkers();
    }
  }

  Future<void> _buildMarkers() async {
    final markers = <String, Marker>{};
    for (final item in widget.listings) {
      final icon = await _pricePinIcon(item.formattedPrice);
      markers[item.id] = Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        onTap: () => _onPinTapped(item),
      );
    }
    if (mounted) {
      setState(() => _markers = markers);
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

  /// Draws a price badge marker ($380 / $4,800) onto a [BitmapDescriptor].
  Future<BitmapDescriptor> _pricePinIcon(String price) async {
    const double pixelRatio = 3;
    const double minWidth = 56;
    const double height = 34;

    final textPainter = TextPainter(
      text: TextSpan(
        text: price,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final width = (textPainter.width + 22).clamp(minWidth, 140.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final rect = Rect.fromLTWH(0, 0, width, height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(17));
    canvas.drawShadow(Path()..addRRect(rrect), Colors.black, 3, false);
    canvas.drawRRect(
      rrect,
      Paint()..color = AppColors.primary,
    );
    // pointer triangle
    final pointer = Path()
      ..moveTo(width / 2 - 6, height - 1)
      ..lineTo(width / 2, height + 7)
      ..lineTo(width / 2 + 6, height - 1)
      ..close();
    canvas.drawPath(pointer, Paint()..color = AppColors.primary);

    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (width * pixelRatio).ceil(),
      (height * pixelRatio + 8 * pixelRatio).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();

    if (bytes == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(
      bytes.buffer.asUint8List(),
      width: width,
      height: height + 8,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _harareCbd,
              zoom: 12.5,
            ),
            style: GoogleMapStyle.lightSilver,
            markers: _markers.values.toSet(),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
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
