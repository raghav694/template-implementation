import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around [FirebaseCrashlytics].
///
/// Call [initialize] once at app startup, right after Firebase itself has
/// been initialized. It wires the global Flutter/Dart error handlers so
/// every uncaught exception is captured automatically from that point on —
/// no call sites elsewhere in the app need to know Crashlytics exists.
class CrashlyticsService {
  CrashlyticsService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final crashlytics = FirebaseCrashlytics.instance;

      // Debug builds never upload — keeps the dashboard free of noise from
      // local development while every real build (dev flavor included)
      // still reports, so regressions are caught before they reach prod.
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Errors thrown by the Flutter framework itself (build/layout/paint,
      // gesture callbacks, etc). Chains the previous handler so debug builds
      // still get the usual red screen / console dump in addition to being
      // reported.
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        previousOnError?.call(details);
        crashlytics.recordFlutterFatalError(details);
      };

      // Uncaught errors outside the Flutter framework — async gaps, Timers,
      // isolates, platform channel callbacks, etc.
      final previousPlatformOnError = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return previousPlatformOnError?.call(error, stack) ?? true;
      };

      _initialized = true;
    } catch (error, stackTrace) {
      // Crashlytics must never be the reason the app it's protecting fails
      // to start.
      debugPrint('CrashlyticsService initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Records a caught, non-fatal error — use this in `catch` blocks for
  /// failures worth investigating that don't otherwise crash the app.
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    if (!_initialized) return Future.value();
    return FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Breadcrumb log line included in the next fatal or non-fatal report.
  static void log(String message) {
    if (!_initialized) return;
    FirebaseCrashlytics.instance.log(message);
  }

  /// Attaches a custom key/value to subsequent fatal and non-fatal reports.
  static void setCustomKey(String key, Object value) {
    if (!_initialized) return;
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Associates subsequent reports with the signed-in user — call on login.
  static void setUserId(String uid) {
    if (!_initialized) return;
    FirebaseCrashlytics.instance.setUserIdentifier(uid);
  }

  /// Call on sign-out. Crashlytics has no "clear identifier" API, so the
  /// documented convention is resetting it to an empty string.
  static void clearUserId() => setUserId('');
}
