import 'package:app_template/config/app_identity.dart';

/// Custom URL scheme and https host used for incoming deep links.
///
/// Paywall / payment links:
/// - `{scheme}://paywall?planId={id}`
/// - `{scheme}://payment?plan_price_id={id}&offer_type=DISCOUNT`
/// - `https://{host}/paywall/{id}`
/// - `https://{host}/payment?planId={id}`
class DeeplinkConfig {
  DeeplinkConfig._();

  static String get scheme => AppIdentity.deeplinkScheme;

  static String get host => AppIdentity.deeplinkHost;

  static bool get isConfigured =>
      scheme.isNotEmpty &&
      !scheme.startsWith('__') &&
      host.isNotEmpty &&
      !host.startsWith('__');

  static bool isConfiguredScheme(String value) {
    return scheme.isNotEmpty &&
        !scheme.startsWith('__') &&
        value.toLowerCase() == scheme.toLowerCase();
  }

  static bool isConfiguredHost(String value) {
    return host.isNotEmpty &&
        !host.startsWith('__') &&
        value.toLowerCase() == host.toLowerCase();
  }

  /// Custom scheme or the app's verified https host — handled in-app.
  static bool isOwnLink(Uri uri) {
    if (isConfiguredScheme(uri.scheme)) return true;
    if (isConfiguredHost(uri.host)) return true;
    return false;
  }

  /// HTTPS hosts that are not our app-links host (shorteners, ads).
  /// These are expanded via `POST /api/v1/deeplinks/resolve`.
  static bool needsResolve(Uri uri) {
    if (isOwnLink(uri)) return false;
    return uri.scheme == 'https' || uri.scheme == 'http';
  }
}
