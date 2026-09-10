import 'package:flutter/widgets.dart';
import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/main.dart' as app;

/// Entry point for the Development flavor.
///
/// ```bash
/// flutter run --flavor dev -t lib/main_dev.dart
/// ```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize(Environment.dev);
  await app.main();
}
