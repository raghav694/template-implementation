import 'package:app_template/features/paywall/domain/repositories/paywall_config.dart';

class FakePaywallConfig implements PaywallConfig {
  FakePaywallConfig({
    this.planVariantId = 'monthly',
    this.controlPlanId = 'monthly',
  });

  @override
  String planVariantId;

  @override
  String controlPlanId;
}
