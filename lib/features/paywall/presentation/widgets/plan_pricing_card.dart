import 'package:flutter/material.dart';

import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/shared/widgets/app_soft_card.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';

class PlanPricingCard extends StatelessWidget {
  const PlanPricingCard({required this.plan, this.skipTrial = false, super.key});

  final Plan plan;
  final bool skipTrial;

  @override
  Widget build(BuildContext context) {
    final showTrialPrice = plan.showTrialPrice(skipTrial: skipTrial);
    final price = showTrialPrice ? plan.trialAmount! : plan.priceAmount;
    final original = plan.originalPriceAmount;
    final discount = plan.discountPercent;

    return AppSoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    plan.currencySymbol,
                    style: AppTypography.textTheme.displayMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
                Text(
                  '$price',
                  style: AppTypography.textTheme.displayLarge?.copyWith(
                    fontSize: 64,
                    color: AppColors.primary,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: showTrialPrice ? 32 : 28,
                    left: 4,
                  ),
                  child: Text(
                    showTrialPrice
                        ? 'today'
                        : plan.isRecurring
                        ? '/${plan.billingPeriodLabel}'
                        : 'once',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!showTrialPrice && original != null && discount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${plan.currencySymbol}$original',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.textDisabled,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.textDisabled,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'SAVE $discount%',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
