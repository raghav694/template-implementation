/// Shared spacing and radius scale used across the app.
///
/// Every screen/widget should pull from this scale instead of hand-picking
/// arbitrary padding/margin/radius values, so density and rhythm stay
/// consistent across the whole product.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Shared corner-radius scale.
class AppRadius {
  AppRadius._();

  /// Chips, small pills, badges.
  static const double sm = 10;

  /// Cards, buttons, tiles.
  static const double md = 14;

  /// Elevated cards, plan cards, hero elements.
  static const double lg = 18;

  /// Bottom sheets, large modal surfaces.
  static const double xl = 24;

  /// Fully round (avatars, icon buttons).
  static const double full = 999;
}
