/// Map tile configuration.
///
/// Primary source: MapTiler Cloud (free tier, fast CDN, no billing).
/// 1. Sign up free at https://cloud.maptiler.com (email only, no card)
/// 2. Copy your key from "API Keys"
/// 3. Paste it below → hot restart
///
/// While the placeholder is unchanged, the app falls back to the keyless
/// Esri light-gray canvas so maps keep working.
class MapTiles {
  /// ⬇⬇⬇ PASTE YOUR MAPTILER API KEY HERE ⬇⬇⬇
  static const String mapTilerKey = 'XR4FGugBioZxCPUrj3Nn';

  /// MapTiler style. 'basic-v2' = clean Google-like look with street names.
  /// Ultra-minimal alternative: 'outline-v2'.
  static const String style = 'basic-v2';

  static bool get _hasKey =>
      mapTilerKey.isNotEmpty && !mapTilerKey.startsWith('PASTE');

  /// Tile URL template for flutter_map ({z}/{x}/{y} placeholders).
  static String get urlTemplate {
    if (_hasKey) {
      return 'https://api.maptiler.com/maps/$style/{z}/{x}/{y}.png'
          '?key=$mapTilerKey';
    }
    // Fallback: keyless Esri Light Gray Canvas (base + street-name overlay).
    return 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/'
        'World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}';
  }

  /// Street-name/label overlay — only needed for the Esri fallback
  /// (MapTiler styles include labels already).
  static String get referenceUrlTemplate =>
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/'
      'World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}';

  /// Show the reference overlay only when running on the Esri fallback.
  static bool get showReferenceOverlay => !_hasKey;

  /// Attribution required by the active provider.
  static String get attribution => _hasKey
      ? '© MapTiler © OpenStreetMap contributors'
      : '© Esri, HERE, Garmin, NGA, USGS';
}
