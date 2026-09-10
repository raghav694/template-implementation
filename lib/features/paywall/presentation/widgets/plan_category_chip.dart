import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:flutter/material.dart';

class PlanCategoryChip extends StatelessWidget {
  const PlanCategoryChip({required this.category, super.key});

  final PlanCategory category;

  @override
  Widget build(BuildContext context) {
    final label = switch (category) {
      PlanCategory.recurring => 'Autopay',
      PlanCategory.oneTime => 'One-time',
    };
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
        label,
        style: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.primaryDim,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
