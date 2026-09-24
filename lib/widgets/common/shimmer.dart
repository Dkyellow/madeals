import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shimmer sweep that animates a highlight gradient across [child].
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFE6E6E6),
    this.highlightColor = const Color(0xFFF6F6F6),
  });

  final Widget child;
  final Duration period;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
              stops: [
                (t * 2 - 1).clamp(0.0, 1.0),
                (t * 2).clamp(0.0, 1.0),
                (t * 2 + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: ColoredBox(color: widget.baseColor, child: child),
        );
      },
    );
  }
}

/// Rounded shimmering block — the basic skeleton primitive.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.radius = 10,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Skeleton mirroring [CompactListingCard] (search results / lists).
class CompactCardSkeleton extends StatelessWidget {
  const CompactCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 100, height: 100, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: double.infinity, height: 14, radius: 6),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    ShimmerBox(width: 54, height: 18, radius: 6),
                    SizedBox(width: 6),
                    ShimmerBox(width: 40, height: 18, radius: 6),
                    SizedBox(width: 6),
                    ShimmerBox(width: 64, height: 18, radius: 6),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerBox(width: 78, height: 17, radius: 6),
                    ShimmerBox(width: 96, height: 11, radius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton mirroring [ListingCard] (home grid).
class GridCardSkeleton extends StatelessWidget {
  const GridCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(
            width: double.infinity,
            height: 125,
            radius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 13, radius: 6),
                SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerBox(width: 14, height: 12, radius: 6),
                    SizedBox(width: 4),
                    Expanded(
                      child: ShimmerBox(width: double.infinity, height: 11, radius: 6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton mirroring [FeaturedListingCard] (home banner).
class FeaturedCardSkeleton extends StatelessWidget {
  const FeaturedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: double.infinity, height: 180, radius: 0),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 220, height: 16, radius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 12, radius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: 180, height: 12, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full home-feed skeleton: category chips + featured + grid rows.
class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            ShimmerBox(width: 70, height: 30, radius: 16),
            SizedBox(width: 8),
            ShimmerBox(width: 64, height: 30, radius: 16),
            SizedBox(width: 8),
            ShimmerBox(width: 76, height: 30, radius: 16),
            SizedBox(width: 8),
            ShimmerBox(width: 88, height: 30, radius: 16),
          ],
        ),
        const SizedBox(height: 16),
        const FeaturedCardSkeleton(),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: GridCardSkeleton()),
            SizedBox(width: 12),
            Expanded(child: GridCardSkeleton()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: GridCardSkeleton()),
            SizedBox(width: 12),
            Expanded(child: GridCardSkeleton()),
          ],
        ),
      ],
    );
  }
}

/// Stacked compact card skeleton list (search results).
class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        CompactCardSkeleton(),
        CompactCardSkeleton(),
        CompactCardSkeleton(),
        CompactCardSkeleton(),
        CompactCardSkeleton(),
      ],
    );
  }
}

/// Product detail skeleton: hero image + title/price + seller + actions.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: double.infinity, height: 270, radius: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 20, radius: 6),
                SizedBox(height: 10),
                ShimmerBox(width: 130, height: 26, radius: 8),
                SizedBox(height: 20),
                Row(
                  children: [
                    ShimmerBox(width: 48, height: 48, radius: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 140, height: 14, radius: 6),
                          SizedBox(height: 6),
                          ShimmerBox(width: 96, height: 11, radius: 6),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ShimmerBox(width: double.infinity, height: 14, radius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 14, radius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 240, height: 14, radius: 6),
                SizedBox(height: 24),
                ShimmerBox(width: double.infinity, height: 150, radius: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
