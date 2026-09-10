/// Remote Config parameter keys. Keep these in sync with the parameters
/// created in the Firebase console.
///
/// Auth is API Phone/OTP only — add product flags here as the app needs them.
class RemoteConfigKeys {
  RemoteConfigKeys._();

  /// Capslock plan id shown when no deeplink plan id is present.
  static const String paywallPlanVariant = 'paywall_plan_variant';

  /// Mandatory store update. Android: Play in-app update on launch and resume
  /// when force is on (also ORed with GrowthBook `forceUpdate`); iOS: App
  /// Store dialog cannot be postponed.
  static const String forceUpdate = 'force_update';

  /// Full-screen maintenance gate.
  static const String isAppUnderMaintenance = 'is_app_under_maintenance';

  /// Headline on the maintenance screen when [isAppUnderMaintenance] is true.
  static const String maintenanceTitle = 'maintenance_title';

  /// Body copy on the maintenance screen when [isAppUnderMaintenance] is true.
  static const String maintenanceMessage = 'maintenance_message';
}

/// In-app default values, applied before the first successful fetch.
class RemoteConfigDefaults {
  RemoteConfigDefaults._();

  static const String controlPlanId = 'monthly';

  static Map<String, dynamic> get values => {
    RemoteConfigKeys.paywallPlanVariant: controlPlanId,
    RemoteConfigKeys.forceUpdate: false,
    RemoteConfigKeys.isAppUnderMaintenance: false,
    RemoteConfigKeys.maintenanceTitle: '',
    RemoteConfigKeys.maintenanceMessage: '',
  };
}
