import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/features/auth/presentation/widgets/auth_accent_glow.dart';
import 'package:flutter/material.dart';

/// Ambient light backdrop with a subtle blue glow in the top-left corner,
/// matching the template's light-theme brand atmosphere.
class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.authTint,
                  AppColors.background,
                  AppColors.background,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        const Positioned(top: -120, left: -80, child: AuthAccentGlow()),
        Positioned.fill(child: child),
      ],
    );
  }
}
