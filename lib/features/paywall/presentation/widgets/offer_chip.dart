import 'package:app_template/core/deeplink/offer_type.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class OfferChip extends StatelessWidget {
  const OfferChip({required this.offerType, super.key});

  final OfferType offerType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        offerType.label,
        style: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.primaryDim,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
