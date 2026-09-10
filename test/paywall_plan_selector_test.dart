import 'package:app_template/features/paywall/domain/entities/paywall_plan_selection.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/services/paywall_plan_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const selector = PaywallPlanSelector();

  const monthly = Plan(
    id: 'monthly',
    label: 'Monthly',
    priceAmount: 149,
    billingCycle: 'month',
  );
  const yearly = Plan(
    id: 'yearly',
    label: 'Yearly',
    priceAmount: 999,
    billingCycle: 'year',
  );
  const lifetime = Plan(
    id: 'lifetime',
    label: 'Lifetime',
    priceAmount: 2999,
    billingCycle: 'once',
    category: PlanCategory.oneTime,
  );

  test('deeplink plan id wins over Remote Config', () {
    final selected = selector.select(
      catalog: const [yearly, monthly],
      deeplinkPlanId: 'yearly',
      variantId: 'monthly',
    );
    expect(selected?.plan.id, 'yearly');
    expect(selected?.source, PaywallPlanSource.deeplink);
  });

  test('uses Remote Config when the URL has no plan id', () {
    final selected = selector.select(
      catalog: const [yearly, monthly],
      variantId: 'yearly',
    );
    expect(selected?.plan.id, 'yearly');
    expect(selected?.source, PaywallPlanSource.remoteConfig);
  });

  test('falls back to Remote Config when the deeplink plan is missing', () {
    final selected = selector.select(
      catalog: const [yearly, monthly],
      deeplinkPlanId: 'gone',
      variantId: 'yearly',
    );
    expect(selected?.plan.id, 'yearly');
    expect(selected?.source, PaywallPlanSource.remoteConfig);
  });

  test('falls back to the control plan when the variant is missing', () {
    final selected = selector.select(
      catalog: const [monthly, yearly],
      variantId: 'experiment_gone',
    );
    expect(selected?.plan.id, 'monthly');
    expect(selected?.source, PaywallPlanSource.control);
  });

  test('falls back to the first catalog plan when control is also missing', () {
    final selected = selector.select(
      catalog: const [yearly, lifetime],
      variantId: 'experiment_gone',
    );
    expect(selected?.plan.id, 'yearly');
    expect(selected?.source, PaywallPlanSource.catalogFallback);
  });

  test('returns null for an empty catalog', () {
    expect(selector.select(catalog: const [], variantId: 'monthly'), isNull);
  });
}
