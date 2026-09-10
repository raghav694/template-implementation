import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';

/// Shared payment-funnel properties for Mixpanel + ad-network mapping.
class PaymentEventProperties {
  PaymentEventProperties._();

  static Map<String, dynamic> fromPlan({
    required Plan plan,
    bool skipTrial = false,
    Map<String, dynamic>? extra,
  }) {
    return {
      AnalyticsProperties.planId: plan.id,
      AnalyticsProperties.trialAmount: skipTrial ? 0 : (plan.trialAmount ?? 0),
      AnalyticsProperties.subscriptionAmount: plan.priceAmount,
      AnalyticsProperties.mediaURL: plan.videoUrl ?? '',
      AnalyticsProperties.planFrequency: plan.billingCycle,
      if (extra != null) ...extra,
    };
  }

  /// UPI discovery / selection props (ShantiClub-compatible keys).
  static Map<String, dynamic> upi({
    required List<String> paymentApps,
    String? selectedPackageName,
    required String paymentMethod,
  }) {
    return {
      AnalyticsProperties.paymentApps: paymentApps,
      AnalyticsProperties.paymentMethod: paymentMethod,
      if (selectedPackageName != null && selectedPackageName.isNotEmpty)
        AnalyticsProperties.selectedPackageName: selectedPackageName,
    };
  }

  /// Amount actually charged today (trial auth charge or full plan price).
  static double chargedAmountInr(Plan plan, {required bool skipTrial}) {
    return plan.chargeAmountFor(skipTrial: skipTrial).toDouble();
  }

  /// Pay-as-you-go / one-time plans only — omitted for subscriptions.
  static double? rechargeAmountInr({
    required Plan plan,
    required double chargedAmountInr,
  }) {
    if (plan.category != PlanCategory.oneTime) return null;
    return chargedAmountInr;
  }

  static String rechargeType(Plan plan) {
    return plan.category == PlanCategory.oneTime
        ? AnalyticsValues.rechargeTypeNormal
        : AnalyticsValues.rechargeTypeSubs;
  }
}
