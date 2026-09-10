import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'package:app_template/core/remote_config/remote_config_keys.dart';

/// Thin wrapper around [FirebaseRemoteConfig].
///
/// Call [initialize] once at app startup, right after Firebase itself has
/// been initialized. Reads fall back to in-app defaults if the fetch never
/// completed, so startup never blocks on Remote Config.
class RemoteConfigService {
  RemoteConfigService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 8),
        ),
      );

      await remoteConfig.setDefaults(RemoteConfigDefaults.values);
      await remoteConfig.fetchAndActivate();

      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('RemoteConfigService initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Re-fetch published values. No-ops if [initialize] never succeeded, or
  /// if the minimum fetch interval has not elapsed.
  static Future<void> refresh() async {
    if (!_initialized) return;
    try {
      await FirebaseRemoteConfig.instance.fetchAndActivate();
    } catch (error, stackTrace) {
      debugPrint('RemoteConfigService refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static String getString(String key) {
    try {
      return FirebaseRemoteConfig.instance.getString(key);
    } catch (_) {
      return '';
    }
  }

  static bool getBool(String key) {
    try {
      return FirebaseRemoteConfig.instance.getBool(key);
    } catch (_) {
      return false;
    }
  }

  static int getInt(String key) {
    try {
      return FirebaseRemoteConfig.instance.getInt(key);
    } catch (_) {
      return 0;
    }
  }
}
