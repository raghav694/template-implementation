import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/deeplink/incoming_deeplink.dart';
import 'package:app_template/core/deeplink/offer_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps /payment plan + offer onto /paywall', () {
    final location = IncomingDeeplink.toAppLocation(
      Uri.parse(
        '/payment?plan_price_id=yearly&offer_type=DISCOUNT&utm_source=fb',
      ),
    );
    expect(
      location,
      '/paywall?planId=yearly&source=DEEPLINK&offerType=DISCOUNT',
    );
  });

  test('keeps an explicit source override', () {
    final location = IncomingDeeplink.toAppLocation(
      Uri.parse('/payment?planId=monthly&source=fb_ads'),
    );
    expect(location, '/paywall?planId=monthly&source=fb_ads');
  });

  test('maps a plan-less /payment onto the paywall with DEEPLINK source', () {
    expect(
      IncomingDeeplink.toAppLocation(Uri.parse('/payment')),
      '/paywall?source=DEEPLINK',
    );
  });

  test('does not open paywall when lbaType is set', () {
    expect(
      IncomingDeeplink.toAppLocation(
        Uri.parse('/payment?planId=yearly&lbaType=9rs'),
      ),
      isNull,
    );
  });

  test('parses offer_type', () {
    expect(
      IncomingDeeplink.offerTypeFrom(Uri.parse('/payment?offer_type=BONUS')),
      OfferType.bonus,
    );
    expect(
      IncomingDeeplink.offerTypeFrom(Uri.parse('/paywall?offerType=discount')),
      OfferType.discount,
    );
  });

  test('maps /home to the app root', () {
    expect(IncomingDeeplink.toAppLocation(Uri.parse('/home')), RoutePaths.home);
  });

  test('ignores unrelated URLs', () {
    expect(
      IncomingDeeplink.toAppLocation(Uri.parse('/chat?accountId=1')),
      isNull,
    );
  });
}
