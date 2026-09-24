import 'package:flutter/material.dart';

/// Tile styling that matches the MADEALS app theme:
/// - Land/roads → bright cool silver (≈ #EFF4F6, sits on the #F5F5F5 UI)
/// - Greens/parks → muted gray
/// - Water → soft blue-gray
/// - Labels → kept dark for readability
/// - Price pins (drawn outside this filter) stay vivid #0062D2
///
/// Applied over free OpenStreetMap tiles — no API key required.
class MapTheme {
  /// Heavy 85% desaturation + lift toward the app's silver palette.
  static const ColorFilter appThemeFilter = ColorFilter.matrix(<double>[
    0.321, 0.590, 0.059, 0, 8, // R
    0.179, 0.750, 0.060, 0, 8, // G
    0.192, 0.644, 0.224, 0, 12, // B: gentle icy-blue cast
    0, 0, 0, 1, 0, // A
  ]);
}
