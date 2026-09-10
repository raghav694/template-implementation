import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/core/utils/date_formatters.dart';
import 'package:app_template/features/paywall/domain/entities/entitlement.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:app_template/features/paywall/presentation/widgets/plan_detail_row.dart';
import 'package:app_template/shared/widgets/app_soft_card.dart';
import 'package:flutter/material.dart';

class PlanDetailsCard extends StatelessWidget {
  const PlanDetailsCard({
    required this.entitlement,
    this.subscription,
    this.plan,
    super.key,
  });

  final Entitlement entitlement;
  final Subscription? subscription;
  final Plan? plan;

  @override
  Widget build(BuildContext context) {
    final isPremium = entitlement.isPremium;
    final name =
        plan?.label ??
        subscription?.planName ??
        subscription?.plan ??
        entitlement.plan ??
        (isPremium ? 'Premium' : 'Free');
    final expiry = subscription?.effectiveExpiresAt ?? entitlement.expiresAt;
    final price = plan?.priceAmount;
    final period = plan?.billingPeriodLabel;
    final status = subscription?.status ?? (isPremium ? 'active' : 'none');

    return AppSoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan details',
            style: AppTypography.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PlanDetailRow(label: 'Plan', value: name),
          PlanDetailRow(
            label: 'Status',
            value: _statusLabel(status, isPremium),
          ),
          if (price != null)
            PlanDetailRow(
              label: 'Price',
              value: period == null
                  ? '${plan!.currencySymbol}$price'
                  : '${plan!.currencySymbol}$price / $period',
            ),
          if (subscription?.provider != null) ...[
            PlanDetailRow(label: 'Gateway', value: subscription!.provider!),
          ],
          if (expiry != null)
            PlanDetailRow(
              label: isPremium ? 'Valid until' : 'Ended',
              value: DateFormatters.profileDate(expiry.toLocal()),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status, bool isPremium) {
    return switch (status.toLowerCase()) {
      'cancelled' || 'canceled' => 'Cancelled',
      'halted' => 'Halted',
      'expired' => 'Expired',
      'pending' || 'initiated' => 'Pending',
      'authenticated' || 'active' || 'past_due' => 'Active',
      _ => isPremium ? 'Active' : 'Free',
    };
  }
}
