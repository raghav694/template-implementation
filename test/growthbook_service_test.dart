import 'package:app_template/core/attribution/utm_data.dart';
import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/growthbook/growthbook_keys.dart';
import 'package:app_template/core/growthbook/growthbook_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(AppConfig.resetForTesting);

  test('empty API key leaves GrowthBook disabled with safe defaults', () async {
    await AppConfig.initializeForTest(
      Environment.dev,
      envContent: '''
API_BASE_URL=https://dev-api.example.com
GROWTHBOOK_API_KEY=
''',
    );
    final growthBook = GrowthBookService();

    await growthBook.initialize();

    expect(AppConfig.hasGrowthBookConfig, isFalse);
    expect(growthBook.isReady, isFalse);
    expect(growthBook.isForceUpdate(), isFalse);
    expect(growthBook.conversionPlanId(), isEmpty);
    expect(growthBook.enabledFeatures(), isEmpty);
  });

  test('applyAttribution stores targeting attributes before init', () {
    final growthBook = GrowthBookService();

    growthBook.applyAttribution(
      const UtmData(
        utmSource: 'facebook',
        utmMedium: 'cpc',
        ref: 'partner',
        gclid: 'g-1',
        gbraid: 'gb-1',
      ),
    );

    expect(
      growthBook.debugAttributes[GrowthBookAttributes.utmSource],
      'facebook',
    );
    expect(growthBook.debugAttributes[GrowthBookAttributes.utmMedium], 'cpc');
    expect(growthBook.debugAttributes[GrowthBookAttributes.ref], 'partner');
    expect(growthBook.debugAttributes[GrowthBookAttributes.gclid], 'g-1');
    expect(growthBook.debugAttributes[GrowthBookAttributes.gbraid], 'gb-1');
  });

  test('setUser keeps userId and isPremium on the attribute map', () {
    final growthBook = GrowthBookService();

    growthBook.setUser(userId: 'user-1', isPremium: true);

    expect(growthBook.debugAttributes[GrowthBookAttributes.userId], 'user-1');
    expect(growthBook.debugAttributes[GrowthBookAttributes.isPremium], isTrue);
  });
}
