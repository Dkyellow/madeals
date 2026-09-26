/// Map tile configuration.
///
/// Source: Esri Light Gray Canvas (keyless, no billing, no quota sign-up).
/// - Base: uniform light-gray land — no green parks, no beige built-up zones,
///   no transit lines, no house numbers.
/// - Reference overlay: street names + road shields (base has no labels).
///
/// Coverage: worldwide z0–13, Africa z14–16. Tiles upscale beyond z16.
class MapTiles {
  /// Plain gray basemap ({z}/{y}/{x} order — Esri convention).
  static const String urlTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/'
      'World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}';

  /// Transparent street-name / road-shield labels drawn above the base.
  static const String referenceUrlTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/'
      'World_Reference_Overlay/MapServer/tile/{z}/{y}/{x}';

  /// Transparent suburb / city / POI names (base and street overlay carry
  /// no place names).
  static const String placesUrlTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/'
      'World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';

  /// Esri serves tiles up to z16 in Africa; ask for higher zooms, we upscale.
  static const int maxNativeZoom = 16;

  /// Always on — the base layer is label-free by design.
  static const bool showReferenceOverlay = true;
  static const bool showPlacesOverlay = true;

  /// Attribution required by Esri (shown in the map's attribution widget).
  static const String attribution =
      '© Esri, HERE, Garmin, OpenStreetMap contributors';
}
