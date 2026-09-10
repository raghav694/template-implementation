import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/firebase/firebase_options_resolver.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized && Firebase.apps.isNotEmpty;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        final options = FirebaseOptionsResolver.forEnvironment(
          AppConfig.environment,
        );
        await Firebase.initializeApp(options: options);

        if (kDebugMode) {
          debugPrint(
            'Firebase initialized: project=${options.projectId}, '
            'env=${AppConfig.environment.name}',
          );
        }
      }

      if (AppConfig.useFirebaseEmulators) {
        await _connectEmulators();
      }

      _initialized = true;
    } catch (error, stackTrace) {
      _initialized = false;
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _connectEmulators() async {
    final host = AppConfig.firebaseEmulatorHost;

    if (kDebugMode) {
      debugPrint('Connecting Firebase emulators at $host');
    }

    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }
}
