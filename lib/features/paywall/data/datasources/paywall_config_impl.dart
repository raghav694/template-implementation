import 'package:app_template/core/growthbook/growthbook_service.dart';
import 'package:app_template/core/remote_config/remote_config_keys.dart';
import 'package:app_template/core/remote_config/remote_config_service.dart';
import 'package:app_template/features/paywall/domain/repositories/paywall_config.dart';

class PaywallConfigImpl implements PaywallConfig {
  const PaywallConfigImpl({required GrowthBookService growthBook})
    : _growthBook = growthBook;

  final GrowthBookService _growthBook;

  @override
  String get planVariantId {
    final fromGrowthBook = _growthBook.conversionPlanId().trim();
    if (fromGrowthBook.isNotEmpty) return fromGrowthBook;
    final value = RemoteConfigService.getString(
      RemoteConfigKeys.paywallPlanVariant,
    ).trim();
    return value.isNotEmpty ? value : controlPlanId;
  }

  @override
  String get controlPlanId => RemoteConfigDefaults.controlPlanId;
}
