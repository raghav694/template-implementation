import 'package:flutter/widgets.dart';
import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/main.dart' as app;

/// Entry point for the Production flavor.
///
/// ```bash
/// flutter run --flavor prod -t lib/main_prod.dart
/// ```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize(Environment.prod);
  await app.main();
}
