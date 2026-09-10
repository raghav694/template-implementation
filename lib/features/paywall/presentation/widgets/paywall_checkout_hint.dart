import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class PaywallCheckoutHint extends StatelessWidget {
  const PaywallCheckoutHint(this.cta, this.message, {super.key});

  final String cta;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(onPressed: null, child: Text(cta)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
