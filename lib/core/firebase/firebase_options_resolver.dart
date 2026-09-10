import 'package:firebase_core/firebase_core.dart';

import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/firebase_options_dev.dart' as dev;
import 'package:app_template/firebase_options_prod.dart' as prod;

/// Selects FlutterFire options for the active flavor [Environment].
class FirebaseOptionsResolver {
  FirebaseOptionsResolver._();

  static FirebaseOptions forEnvironment(Environment environment) {
    return switch (environment) {
      Environment.dev => dev.DefaultFirebaseOptions.currentPlatform,
      Environment.prod => prod.DefaultFirebaseOptions.currentPlatform,
    };
  }
}
