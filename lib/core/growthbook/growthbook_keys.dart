/// GrowthBook feature keys and in-app fallbacks.
///
/// Dashboard keys must match these strings exactly. A missing key, a failed
/// fetch, or an unset `GROWTHBOOK_API_KEY` resolves to the matching default —
/// reads are always safe.
class GrowthBookKeys {
  GrowthBookKeys._();

  /// Capslock plan id for the paywall. Same string as Remote Config
  /// `paywall_plan_variant`. A `planId` deeplink still wins over this.
  static const String conversionPlanId = 'paywall_plan_variant';

  /// When on, Android in-app update runs on launch and resume if Play has a
  /// newer build. ORed with Remote Config / config API `force_update`.
  static const String forceUpdate = 'forceUpdate';

  static const List<String> known = [conversionPlanId, forceUpdate];
}

class GrowthBookDefaults {
  GrowthBookDefaults._();

  static const String fallbackPlanId = 'monthly';
}

/// Targeting attribute names. `id` is the bucketing attribute and must stay
/// stable for a given install.
class GrowthBookAttributes {
  GrowthBookAttributes._();

  static const String id = 'id';
  static const String userId = 'userId';
  static const String anonymousId = 'anonymousId';
  static const String languageCode = 'languageCode';
  static const String platform = 'platform';
  static const String appVersion = 'appVersion';
  static const String isPremium = 'isPremium';
  static const String utmSource = 'utmSource';
  static const String utmMedium = 'utmMedium';
  static const String ref = 'ref';
  static const String gclid = 'gclid';
  static const String gbraid = 'gbraid';
}
