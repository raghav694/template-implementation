import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/firebase/firebase_options_resolver.dart';
import 'package:app_template/firebase_options_dev.dart' as dev;
import 'package:app_template/firebase_options_prod.dart' as prod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dev environment resolves to the dev Firebase options', () {
    final options = FirebaseOptionsResolver.forEnvironment(Environment.dev);
    expect(options.projectId, dev.DefaultFirebaseOptions.android.projectId);
  });

  test('prod environment resolves to the prod Firebase options', () {
    final options = FirebaseOptionsResolver.forEnvironment(Environment.prod);
    expect(options.projectId, prod.DefaultFirebaseOptions.android.projectId);
  });
}
