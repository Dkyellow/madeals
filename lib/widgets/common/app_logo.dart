import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final bool isLight;

  const AppLogo({
    super.key,
    this.fontSize = 24,
    this.showTagline = false,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final markSize = fontSize * 1.75;
    final wordStyle = GoogleFonts.inter(
      fontSize: fontSize * 1.05,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
      height: 1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gradient app mark
            Container(
              width: markSize,
              height: markSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(markSize * 0.32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: fontSize * 1.1,
              ),
            ),
            SizedBox(width: fontSize * 0.4),
            // Wordmark: MADEALS
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'MA',
                  style: wordStyle.copyWith(
                    color: isLight ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'DEALS',
                  style: wordStyle.copyWith(
                    color: isLight ? Colors.white : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 5),
            // Zimbabwe green live dot
            Container(
              width: fontSize * 0.32,
              height: fontSize * 0.32,
              decoration: BoxDecoration(
                color: AppColors.zimGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.zimGreen.withValues(alpha: 0.45),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 5),
          Text(
            "Zimbabwe's direct discovery marketplace",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isLight ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
