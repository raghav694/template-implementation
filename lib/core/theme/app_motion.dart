import 'package:flutter/animation.dart';

/// Shared motion tokens — every state change (tab switch, card tap, toggle,
/// sheet open) should use one of these durations/curves instead of a
/// one-off value, so movement feels like a single consistent system.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve curve = Curves.easeOutCubic;

  /// Scale target for press/tap feedback on cards and buttons.
  static const double pressedScale = 0.96;
}
