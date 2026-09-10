import 'package:app_template/features/paywall/domain/entities/plan.dart';

/// Why this plan is the one on the paywall. Useful for analytics.
enum PaywallPlanSource {
  /// Incoming deeplink carried a plan id that exists in the catalog.
  deeplink,

  /// Payment settings Renew forced the cancelled subscription's Capslock plan.
  forced,

  /// Remote Config `paywall_plan_variant` matched a catalog plan.
  remoteConfig,

  /// Variant missing; used the control plan id.
  control,

  /// Deeplink / Remote Config / control all missing; first catalog plan.
  catalogFallback,
}

class PaywallPlanSelection {
  const PaywallPlanSelection({
    required this.plan,
    required this.source,
    required this.requestedPlanId,
  });

  final Plan plan;
  final PaywallPlanSource source;

  /// The id we tried first (deeplink, else Remote Config variant).
  final String requestedPlanId;
}
