import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Text(
          label,
          style: AppTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
