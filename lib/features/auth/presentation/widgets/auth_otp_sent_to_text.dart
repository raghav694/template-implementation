import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AuthOtpSentToText extends StatelessWidget {
  const AuthOtpSentToText({required this.phoneNo, super.key});

  final String phoneNo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Text.rich(
        TextSpan(
          text: 'Enter the 6-digit code sent to ',
          children: [
            TextSpan(
              text: phoneNo,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}
