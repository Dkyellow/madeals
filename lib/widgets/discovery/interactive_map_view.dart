import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/listing_item.dart';

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
  String? selectedListingId;

  // Relative pin coordinates for stylized Harare vector map
  final Map<String, Offset> _pinCoordinates = {
    'deal_01': const Offset(0.48, 0.52), // Harare Central ($4,800)
    'deal_02': const Offset(0.35, 0.38), // Avondale ($380)
    'deal_03': const Offset(0.70, 0.48), // Eastlea ($1,650)
    'deal_04': const Offset(0.68, 0.22), // Borrowdale ($510)
    'deal_05': const Offset(0.24, 0.58), // Belvedere ($3,600)
    'deal_06': const Offset(0.45, 0.28), // Mount Pleasant ($590)
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5ECF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            // Custom Painter for Roads, Harare Green Belts, Grid
            Positioned.fill(
              child: CustomPaint(
                painter: _HarareMapPainter(),
              ),
            ),
            // Map Location Label
            Positioned(
              top: 12,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
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
                    const Icon(Icons.explore_rounded, color: AppColors.primary, size: 14),
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
            // Price Pins
            ...widget.listings.take(6).map((item) {
              final coord = _pinCoordinates[item.id] ?? const Offset(0.5, 0.5);
              final isSelected = selectedListingId == item.id;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final x = coord.dx * constraints.maxWidth;
                  final y = coord.dy * constraints.maxHeight;

                  return Positioned(
                    left: x - (isSelected ? 36 : 28),
                    top: y - 20,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedListingId = item.id;
                        });
                        widget.onPinSelected(item);
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: _buildMapPin(item, isSelected),
                      ),
                    ),
                  );
                },
              );
            }),
            // Bottom Legend
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
                  'Tap Pin to View Harare Deal',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin(ListingItem item, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.zimGreen : AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.category.toLowerCase() == 'vehicles'
                ? Icons.directions_car
                : Icons.phone_iphone,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            item.formattedPrice,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HarareMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final greenParkPaint = Paint()
      ..color = const Color(0xFFD1E7DD).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Parks (e.g. Harare Gardens)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.42, size.height * 0.44, 50, 35),
        const Radius.circular(8),
      ),
      greenParkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.18, 60, 45),
        const Radius.circular(12),
      ),
      greenParkPaint,
    );

    // Samora Machel Avenue
    final mainArtery = Path();
    mainArtery.moveTo(0, size.height * 0.52);
    mainArtery.lineTo(size.width, size.height * 0.50);
    canvas.drawPath(mainArtery, roadPaint);

    // Julius Nyerere / Borrowdale Road
    final northSouth = Path();
    northSouth.moveTo(size.width * 0.48, size.height);
    northSouth.quadraticBezierTo(
      size.width * 0.46,
      size.height * 0.4,
      size.width * 0.62,
      0,
    );
    canvas.drawPath(northSouth, roadPaint);

    // Secondary Arteries
    final diagonal1 = Path();
    diagonal1.moveTo(0, size.height * 0.2);
    diagonal1.lineTo(size.width * 0.5, size.height * 0.5);
    canvas.drawPath(diagonal1, secondaryRoadPaint);

    final diagonal2 = Path();
    diagonal2.moveTo(size.width * 0.3, size.height);
    diagonal2.lineTo(size.width * 0.85, size.height * 0.1);
    canvas.drawPath(diagonal2, secondaryRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
