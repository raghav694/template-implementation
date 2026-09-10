import 'package:app_template/core/growthbook/growthbook_keys.dart';
import 'package:app_template/features/paywall/data/datasources/paywall_config_impl.dart';
import 'package:app_template/features/paywall/domain/repositories/paywall_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_growthbook_service.dart';

void main() {
  test('GrowthBook conversion plan wins over Remote Config fallback', () {
    final PaywallConfig config = PaywallConfigImpl(
      growthBook: FakeGrowthBookService(planId: 'yearly'),
    );

    expect(config.planVariantId, 'yearly');
    expect(config.controlPlanId, GrowthBookDefaults.fallbackPlanId);
  });

  test('empty GrowthBook plan falls through to the control id without RC', () {
    final config = PaywallConfigImpl(growthBook: FakeGrowthBookService());

    expect(config.planVariantId, GrowthBookDefaults.fallbackPlanId);
  });
}
