/// Reads the default paywall plan assignment. Production impl prefers
/// GrowthBook `paywall_plan_variant` when that feature is on, then Remote
/// Config. Deeplink plan ids are passed separately into the resolver.
abstract class PaywallConfig {
  /// Plan id assigned to this install (`paywall_plan_variant`).
  String get planVariantId;

  /// Always-safe plan id when the variant is missing from the catalog.
  String get controlPlanId;
}
