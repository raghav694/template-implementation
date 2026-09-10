/// Compile-time app identity generated from [project_config.yaml].
///
/// Run `./scripts/setup_project.sh` after cloning this template. That script
/// rewrites this file from the YAML so app-specific values live in one place.
class AppIdentity {
  AppIdentity._();

  static const String appName = '__APP_NAME__';
  static const String dartPackage = 'app_template';
  static const String androidPackage = '__ANDROID_PACKAGE__';
  static const String iosBundleId = '__IOS_BUNDLE_ID__';
  static const String supportEmail = '__SUPPORT_EMAIL__';
  static const String termsUrl = '__TERMS_URL__';
  static const String privacyUrl = '__PRIVACY_URL__';
  static const String refundUrl = '__REFUND_URL__';
  static const String deeplinkScheme = '__APP_SCHEME__';
  static const String deeplinkHost = '__DEEPLINK_HOST__';
}
