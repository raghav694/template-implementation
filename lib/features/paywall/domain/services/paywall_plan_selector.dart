import 'package:app_template/features/paywall/domain/entities/paywall_plan_selection.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';

/// Picks the single plan the paywall should render.
///
/// 1. Deeplink plan id, when the catalog has it.
/// 2. GrowthBook / Remote Config variant id (`paywall_plan_variant`).
/// 3. Control plan id (default `monthly`).
/// 4. First catalog plan.
class PaywallPlanSelector {
  const PaywallPlanSelector({this.controlPlanId = 'monthly'});

  final String controlPlanId;

  PaywallPlanSelection? select({
    required List<Plan> catalog,
    String? deeplinkPlanId,
    required String variantId,
  }) {
    if (catalog.isEmpty) return null;

    final deeplinkId = deeplinkPlanId?.trim();
    if (deeplinkId != null && deeplinkId.isNotEmpty) {
      final fromLink = _find(catalog, deeplinkId);
      if (fromLink != null) {
        return PaywallPlanSelection(
          plan: fromLink,
          source: PaywallPlanSource.deeplink,
          requestedPlanId: deeplinkId,
        );
      }
    }

    final requested = (deeplinkId != null && deeplinkId.isNotEmpty)
        ? deeplinkId
        : variantId;

    final variant = _find(catalog, variantId);
    if (variant != null) {
      return PaywallPlanSelection(
        plan: variant,
        source: PaywallPlanSource.remoteConfig,
        requestedPlanId: requested,
      );
    }

    if (variantId != controlPlanId) {
      final control = _find(catalog, controlPlanId);
      if (control != null) {
        return PaywallPlanSelection(
          plan: control,
          source: PaywallPlanSource.control,
          requestedPlanId: requested,
        );
      }
    }

    return PaywallPlanSelection(
      plan: catalog.first,
      source: PaywallPlanSource.catalogFallback,
      requestedPlanId: requested,
    );
  }

  Plan? _find(List<Plan> catalog, String id) {
    for (final plan in catalog) {
      if (plan.id == id) return plan;
    }
    return null;
  }
}
