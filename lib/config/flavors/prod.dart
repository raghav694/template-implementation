import 'package:app_template/config/environment.dart';

/// Production flavor metadata. The Flutter entrypoint is [lib/main_prod.dart].
class ProdFlavor {
  ProdFlavor._();

  static const Environment environment = Environment.prod;
  static const String envFile = '.env.prod';
  static const String firebaseOptionsFile = 'lib/firebase_options_prod.dart';
}
