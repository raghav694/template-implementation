import 'package:flutter/material.dart';

import 'package:app_template/core/theme/app_motion.dart';

/// Custom fade + slight upward slide transition, using the shared
/// [AppMotion] duration/curve tokens so route transitions feel like part of
/// the same motion system as in-screen animations.
class FadeSlidePage<T> extends Page<T> {
  const FadeSlidePage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.duration = AppMotion.medium,
  });

  final Widget child;
  final Duration duration;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.curve,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
