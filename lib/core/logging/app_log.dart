import 'package:flutter/foundation.dart';

/// Lightweight debug logger. Production diagnostics go through Crashlytics.
class AppLog {
  AppLog._();

  static void d(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint(message);
    if (error != null) {
      debugPrint(error.toString());
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
