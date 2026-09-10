import 'package:flutter/material.dart';

/// Color tokens — one accent on a cool light canvas.
///
/// Surfaces stay white/soft-blue so content and hierarchy carry the weight.
/// Destructive actions keep a distinct coral/red. Override these values when
/// theming a new app.
class AppColors {
  AppColors._();

  // ── Backgrounds (cool off-white) ──────────────────────────────────────────
  static const Color background = Color(0xFFF5F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFEEF3FA);
  static const Color surfaceHigh = Color(0xFFE3EAF4);

  // ── Trust blue accent ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryGlow = Color(0x251E88E5);
  static const Color primaryDim = Color(0xFF1565C0);
  static const Color primarySoft = Color(0xFFE3F2FD);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F2744);
  static const Color textSecondary = Color(0xFF5A6B7D);
  static const Color textDisabled = Color(0xFFA0AEC0);

  // ── Structural ────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFE05252);
  static const Color success = Color(0xFF43A047);

  // ── Semantic aliases (backward-compatible names used across the codebase) ─
  /// Use for error/destructive actions (sign-out, error banners).
  static const Color accent = error;

  /// Premium indicator — same as [primary].
  static const Color accentGold = primary;

  // ── Gradient helpers ─────────────────────────────────────────────────────
  static const Color gradient1 = Color(0xFF42A5F5);
  static const Color gradient2 = Color(0xFF1565C0);

  /// Ambient screen backdrop — very subtle accent radial glow.
  static const Color ambientGlow = Color(0x151E88E5);

  /// Soft blue wash used on auth / atmosphere backgrounds.
  static const Color authTint = Color(0xFFEEF5FF);

  // ── Elevation ─────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x140F2744);

  static List<BoxShadow> get softShadow => const [
    BoxShadow(color: shadow, blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A0F2744), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradient1, primary, gradient2],
    stops: [0.0, 0.55, 1.0],
  );
}
