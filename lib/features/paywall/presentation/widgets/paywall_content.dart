import 'package:app_template/core/constants/paywall_sources.dart';
import 'package:app_template/core/deeplink/offer_type.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/paywall/domain/entities/paywall_plan_selection.dart';
import 'package:app_template/features/paywall/presentation/widgets/offer_chip.dart';
import 'package:app_template/features/paywall/presentation/widgets/plan_category_chip.dart';
import 'package:app_template/features/paywall/presentation/widgets/plan_pricing_card.dart';
import 'package:app_template/features/paywall/presentation/widgets/paywall_cta.dart';
import 'package:flutter/material.dart';

class PaywallContent extends StatelessWidget {
  const PaywallContent({
    required this.selection,
    this.offerType,
    this.source,
    super.key,
  });

  final PaywallPlanSelection selection;
  final OfferType? offerType;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final plan = selection.plan;
    final isRenewal = PaywallSources.isRenewal(source);
    final skipTrial = isRenewal;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              120,
            ),
            children: [
              Text(
                isRenewal ? 'Renew subscription' : 'Go Premium',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.displaySmall?.copyWith(
                  height: 1.2,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                plan.label,
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PlanPricingCard(plan: plan, skipTrial: skipTrial),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  PlanCategoryChip(category: plan.category),
                  if (offerType != null) OfferChip(offerType: offerType!),
                ],
              ),
            ],
          ),
        ),
        PaywallCta(plan: plan, source: source, offerType: offerType),
      ],
    );
  }
}
