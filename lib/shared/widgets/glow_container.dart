import 'package:flutter/material.dart';

import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';

/// A card-like container with a soft colored glow behind it.
class GlowContainer extends StatelessWidget {
  const GlowContainer({
    required this.child,
    this.glowColor = AppColors.primary,
    this.borderColor,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = AppSpacing.lg,
    this.glowOpacity = 0.28,
    this.glowBlur = 24,
    super.key,
  });

  final Widget child;
  final Color glowColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double glowOpacity;
  final double glowBlur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? glowColor.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: glowOpacity),
            blurRadius: glowBlur,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
