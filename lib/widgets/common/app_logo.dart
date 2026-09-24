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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'MA',
                    style: GoogleFonts.inter(
                      fontSize: fontSize * 0.8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'DEALS',
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: isLight ? Colors.white : AppColors.textPrimary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.zimGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
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
