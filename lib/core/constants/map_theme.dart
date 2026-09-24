import 'package:flutter/material.dart';

/// Tile styling that matches the MADEALS app theme:
/// - Land/background → cool light silver (close to #F5F5F5)
/// - Water → soft blue tint (primaryLight family)
/// - Greens/parks → muted, desaturated
/// - Labels → kept dark (#111-style) for readability
///
/// Applied over free OpenStreetMap tiles — no API key required.
class MapTheme {
  static const ColorFilter appThemeFilter = ColorFilter.matrix(<double>[
    0.633, 0.315, 0.032, 0, 4, // R: 55% desaturation + slight lift
    0.096, 0.872, 0.032, 0, 4, // G
    0.098, 0.328, 0.594, 0, 7, // B: cool blue-silver bias
    0, 0, 0, 1, 0, // A
  ]);
}
