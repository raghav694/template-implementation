import 'package:app_template/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

const _testEnv = '''
MIXPANEL_TOKEN=
USE_FIREBASE_EMULATORS=false
FIREBASE_EMULATOR_HOST=127.0.0.1
FIREBASE_FUNCTIONS_REGION=asia-south1
API_BASE_URL=https://dev-api.example.com
''';

void main() {
  tearDown(AppConfig.resetForTesting);

  test('loads dev configuration from dotenv', () async {
    await AppConfig.initializeForTest(Environment.dev, envContent: _testEnv);

    expect(AppConfig.environment, Environment.dev);
    expect(AppConfig.useFirebaseEmulators, isFalse);
    expect(AppConfig.firebaseEmulatorHost, '127.0.0.1');
    expect(AppConfig.apiBaseUrl, 'https://dev-api.example.com');
    expect(AppConfig.firebaseFunctionsRegion, 'asia-south1');
    expect(AppConfig.hasMixpanel, isFalse);
    expect(AppConfig.hasPaymentsConfig, isFalse);
    expect(AppConfig.hasAuthConfig, isFalse);
    expect(AppConfig.authOrigin, 'https://dev-api.example.com');
    expect(AppConfig.hasTruecaller, isFalse);
    expect(AppConfig.hasGrowthBookConfig, isFalse);
    expect(AppConfig.growthBookHostUrl, 'https://cdn.growthbook.io/');
  });

  test('growthbook is enabled when an API key is set', () async {
    await AppConfig.initializeForTest(
      Environment.dev,
      envContent: '''
API_BASE_URL=https://dev-api.example.com
GROWTHBOOK_HOST_URL=https://cdn.example.com/
GROWTHBOOK_API_KEY=sdk-test
''',
    );

    expect(AppConfig.growthBookHostUrl, 'https://cdn.example.com/');
    expect(AppConfig.growthBookApiKey, 'sdk-test');
    expect(AppConfig.hasGrowthBookConfig, isTrue);
  });

  test('truecaller is enabled when a client id is set', () async {
    await AppConfig.initializeForTest(
      Environment.dev,
      envContent: '''
API_BASE_URL=https://dev-api.example.com
TRUECALLER_CLIENT_ID=test-client-id
''',
    );

    expect(AppConfig.truecallerClientId, 'test-client-id');
    expect(AppConfig.hasTruecaller, isTrue);
  });

  test('payments config requires both origin and tenant', () async {
    await AppConfig.initializeForTest(
      Environment.dev,
      envContent: '''
API_BASE_URL=https://dev-api.example.com
PAYMENTS_BASE_URL=https://payments.example.com/
PAYMENTS_TENANT_ID=tenant-1
''',
    );

    expect(AppConfig.paymentsBaseUrl, 'https://payments.example.com');
    expect(AppConfig.paymentsTenantId, 'tenant-1');
    expect(AppConfig.hasPaymentsConfig, isTrue);
  });

  test('auth config requires both origin and tenant', () async {
    await AppConfig.initializeForTest(
      Environment.dev,
      envContent: '''
API_BASE_URL=https://dev-api.example.com
AUTH_BASE_URL=https://auth.example.com/
AUTH_TENANT_ID=auth-tenant-1
''',
    );

    expect(AppConfig.authBaseUrl, 'https://auth.example.com');
    expect(AppConfig.authTenantId, 'auth-tenant-1');
    expect(AppConfig.hasAuthConfig, isTrue);
    expect(AppConfig.authOrigin, 'https://auth.example.com');
  });

  test('prod requires API_BASE_URL', () async {
    await AppConfig.initializeForTest(
      Environment.prod,
      envContent: 'API_BASE_URL=',
    );

    expect(AppConfig.isProd, isTrue);
    expect(AppConfig.hasApiBaseUrl, isFalse);
  });
}
