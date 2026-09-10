import 'package:flutter/material.dart';

import 'package:app_template/core/theme/app_colors.dart';

/// Circular blue badge with a centered glyph — used for list rows and CTAs.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    required this.icon,
    this.size = 44,
    this.iconSize = 22,
    this.color,
    this.backgroundColor,
    super.key,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}
