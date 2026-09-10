import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AuthHeadline extends StatelessWidget {
  const AuthHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Welcome',
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in with your phone number to get started.',
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
