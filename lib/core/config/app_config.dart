import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/config/environment.dart';
import 'package:app_template/config/flavors/dev.dart';
import 'package:app_template/config/flavors/prod.dart';

export '../../config/environment.dart';

/// Application configuration loaded from flavor-specific `.env` files.
///
/// Initialize via [main_dev.dart] or [main_prod.dart] before accessing values.
/// Secrets belong in gitignored `.env.dev` / `.env.prod`, not in Dart source.
class AppConfig {
  AppConfig._();

  static const String _environmentKey = 'app_environment';
  static Environment? _environment;
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static String envFileName(Environment environment) {
    return switch (environment) {
      Environment.dev => DevFlavor.envFile,
      Environment.prod => ProdFlavor.envFile,
    };
  }

  /// Initialize by loading the `.env` file for the active flavor.
  static Future<void> initialize(Environment environment) async {
    _environment ??= environment;
    await dotenv.load(fileName: envFileName(environment));
    _isInitialized = true;
    _validate();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_environmentKey, environment.name);

    if (kDebugMode) {
      debugPrint(
        'AppConfig: env=${environment.name}, '
        'emulators=$useFirebaseEmulators, '
        'mixpanel=${hasMixpanel ? 'configured' : 'disabled'}, '
        'apiBaseUrl=${apiBaseUrl.isNotEmpty ? 'configured' : 'missing'}, '
        'auth=${hasAuthConfig ? 'configured' : 'disabled'}, '
        'payments=${hasPaymentsConfig ? 'configured' : 'disabled'}, '
        'truecaller=${hasTruecaller ? 'configured' : 'disabled'}, '
        'growthbook=${hasGrowthBookConfig ? 'configured' : 'disabled'}',
      );
    }
  }

  /// Loads env in background isolates (e.g. FCM handlers).
  static Future<void> initializeForBackground() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final envName = prefs.getString(_environmentKey);
      _environment = Environment.fromName(envName);

      if (_environment != null) {
        await dotenv.load(fileName: envFileName(_environment!));
        _isInitialized = true;
      }
    } catch (_) {
      _isInitialized = false;
    }
  }

  static Environment get environment => _environment ?? Environment.prod;

  static bool get isDev => _environment == Environment.dev;

  static bool get isProd => _environment == Environment.prod;

  static bool get showDebugBanner => isDev && kDebugMode;

  static String get mixpanelToken => dotenv.env['MIXPANEL_TOKEN']?.trim() ?? '';

  static bool get useFirebaseEmulators => _readBool('USE_FIREBASE_EMULATORS');

  static String get firebaseEmulatorHost =>
      dotenv.env['FIREBASE_EMULATOR_HOST']?.trim().isNotEmpty == true
      ? dotenv.env['FIREBASE_EMULATOR_HOST']!.trim()
      : '127.0.0.1';

  static String get firebaseFunctionsRegion =>
      dotenv.env['FIREBASE_FUNCTIONS_REGION']?.trim() ?? '';

  static bool get hasMixpanel => mixpanelToken.isNotEmpty;

  /// Backend origin only (no path). Paths are absolute `/api/v1/...`
  /// in the network layer. Events, deeplinks, and config status use this.
  static String get apiBaseUrl => _origin(dotenv.env['API_BASE_URL']);

  static bool get hasApiBaseUrl => apiBaseUrl.isNotEmpty;

  /// Auth service origin (OTP, refresh, profile). Required with [authTenantId].
  static String get authBaseUrl => _origin(dotenv.env['AUTH_BASE_URL']);

  /// Tenant segment in `/public/tenants/{tenantCode}/...`. Required with
  /// [authBaseUrl] for [hasAuthConfig].
  static String get authTenantId => dotenv.env['AUTH_TENANT_ID']?.trim() ?? '';

  static bool get hasAuthConfig =>
      authBaseUrl.isNotEmpty && authTenantId.isNotEmpty;

  /// Host used by [AuthApiService] and token refresh. Auth calls still require
  /// [hasAuthConfig] because the tenant is part of the path.
  static String get authOrigin => hasAuthConfig ? authBaseUrl : apiBaseUrl;

  /// Capslock Payments checkout origin (no path). Empty disables checkout.
  static String get paymentsBaseUrl => _origin(dotenv.env['PAYMENTS_BASE_URL']);

  static String get paymentsTenantId =>
      dotenv.env['PAYMENTS_TENANT_ID']?.trim() ?? '';

  static bool get hasPaymentsConfig =>
      paymentsBaseUrl.isNotEmpty && paymentsTenantId.isNotEmpty;

  /// Truecaller OAuth client id. Empty hides the auth-screen CTA.
  static String get truecallerClientId =>
      dotenv.env['TRUECALLER_CLIENT_ID']?.trim() ?? '';

  static bool get hasTruecaller => truecallerClientId.isNotEmpty;

  /// GrowthBook features endpoint, e.g. `https://cdn.growthbook.io/`.
  static String get growthBookHostUrl {
    final raw = dotenv.env['GROWTHBOOK_HOST_URL']?.trim() ?? '';
    return raw.isNotEmpty ? raw : 'https://cdn.growthbook.io/';
  }

  /// GrowthBook client key (`sdk-…`). Empty disables GrowthBook entirely and
  /// every flag falls back to its in-app default.
  static String get growthBookApiKey =>
      dotenv.env['GROWTHBOOK_API_KEY']?.trim() ?? '';

  static bool get hasGrowthBookConfig => growthBookApiKey.isNotEmpty;

  static void _validate() {
    if (isProd && !hasApiBaseUrl) {
      throw StateError(
        'API_BASE_URL must be set in .env.prod for production builds.',
      );
    }
  }

  static String _origin(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  static bool _readBool(String key, {bool defaultValue = false}) {
    final raw = dotenv.env[key]?.trim().toLowerCase() ?? '';
    if (raw.isEmpty) return defaultValue;
    return switch (raw) {
      '1' || 'true' || 'yes' => true,
      '0' || 'false' || 'no' => false,
      _ => defaultValue,
    };
  }

  @visibleForTesting
  static Future<void> initializeForTest(
    Environment environment, {
    required String envContent,
  }) async {
    _environment = environment;
    dotenv.loadFromString(envString: envContent);
    _isInitialized = true;
  }

  @visibleForTesting
  static void resetForTesting() {
    _environment = null;
    _isInitialized = false;
    if (dotenv.isInitialized) {
      dotenv.clean();
    }
  }
}
