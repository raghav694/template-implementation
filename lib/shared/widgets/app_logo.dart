import 'package:flutter/material.dart';

import 'package:app_template/config/app_identity.dart';
import 'package:app_template/core/theme/app_colors.dart';

/// Generic app mark. Replace [assets/logo/logo.png] with product artwork.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.showName = false,
    this.nameStyle,
    this.borderRadius,
  });

  final double size;
  final bool showName;
  final TextStyle? nameStyle;
  final double? borderRadius;

  static const String _asset = 'assets/logo/logo.png';

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.22;

    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        _asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: AppColors.primary,
            alignment: Alignment.center,
            child: Icon(
              Icons.apps_rounded,
              color: Colors.white,
              size: size * 0.55,
            ),
          );
        },
      ),
    );

    if (!showName) return mark;

    final displayName = AppIdentity.appName.startsWith('__')
        ? 'App'
        : AppIdentity.appName;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        SizedBox(width: size * 0.28),
        Text(
          displayName,
          style:
              nameStyle ??
              TextStyle(
                fontSize: size * 0.44,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
        ),
      ],
    );
  }
}
