import 'package:app_template/config/environment.dart';

/// Development flavor metadata. The Flutter entrypoint is [lib/main_dev.dart].
class DevFlavor {
  DevFlavor._();

  static const Environment environment = Environment.dev;
  static const String envFile = '.env.dev';
  static const String firebaseOptionsFile = 'lib/firebase_options_dev.dart';
}
