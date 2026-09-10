import 'package:app_template/features/paywall/domain/services/paywall_deeplink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads planId from query parameters', () {
    expect(
      PaywallDeeplink.planIdFrom(Uri.parse('/paywall?planId=yearly')),
      'yearly',
    );
    expect(
      PaywallDeeplink.planIdFrom(Uri.parse('/paywall?plan_id=monthly')),
      'monthly',
    );
    expect(
      PaywallDeeplink.planIdFrom(Uri.parse('/paywall?plan=lifetime')),
      'lifetime',
    );
  });

  test('reads plan id from the path', () {
    expect(PaywallDeeplink.planIdFrom(Uri.parse('/paywall/yearly')), 'yearly');
    expect(
      PaywallDeeplink.planIdFrom(Uri.parse('app://host/paywall/monthly')),
      'monthly',
    );
    expect(
      PaywallDeeplink.planIdFrom(Uri.parse('app://paywall/yearly')),
      'yearly',
    );
  });

  test('reads planId from a custom-scheme host', () {
    expect(
      PaywallDeeplink.planIdFrom(Uri.parse('app://paywall?planId=yearly')),
      'yearly',
    );
  });

  test('reads plan_price_id from a payment deeplink', () {
    expect(
      PaywallDeeplink.planIdFrom(
        Uri.parse('/payment?plan_price_id=yearly&offer_type=DISCOUNT'),
      ),
      'yearly',
    );
    expect(PaywallDeeplink.looksLikePaywall(Uri.parse('/payment')), isTrue);
  });

  test('returns null when the app has no deeplink plan', () {
    expect(PaywallDeeplink.planIdFrom(Uri.parse('/paywall')), isNull);
    expect(PaywallDeeplink.planIdFrom(Uri.parse('/home')), isNull);
    expect(
      PaywallDeeplink.planIdFrom(Uri.parse('/profile?planId=yearly')),
      isNull,
    );
  });
}
