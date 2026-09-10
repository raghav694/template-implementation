import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/attribution/attribution_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/recording_analytics_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves utm_source and utm_medium from a deeplink', () async {
    final store = AttributionStore(
      prefs: await SharedPreferences.getInstance(),
    );

    await store.saveFromUri(
      Uri.parse(
        'https://links.example.com/paywall?utm_source=facebook&utm_medium=cpc',
      ),
    );

    expect(store.data.utmSource, 'facebook');
    expect(store.data.utmMedium, 'cpc');
    expect(store.data.onboardingDeeplink, contains('utm_source=facebook'));
  });

  test('also reads camelCase utm keys', () async {
    final store = AttributionStore(
      prefs: await SharedPreferences.getInstance(),
    );
    await store.saveFromUri(
      Uri.parse('/payment?utmSource=google&utmMedium=uac'),
    );
    expect(store.data.utmSource, 'google');
    expect(store.data.utmMedium, 'uac');
  });

  test('applies UTM to analytics with set-once keys', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = AttributionStore(prefs: prefs);
    await store.saveFromUri(
      Uri.parse('/payment?utm_source=fb&utm_medium=paid'),
    );
    final analytics = RecordingAnalyticsService();
    await store.applyToAnalytics(analytics);

    expect(analytics.onceProperties[AnalyticsUserProperties.utmSource], 'fb');
    expect(analytics.onceProperties[AnalyticsUserProperties.utmMedium], 'paid');
  });

  test('consumes Play Install Referrer only once', () async {
    final store = AttributionStore(
      prefs: await SharedPreferences.getInstance(),
    );
    expect(await store.consumePlayReferrer(), isTrue);
    expect(await store.consumePlayReferrer(), isFalse);
  });
}
