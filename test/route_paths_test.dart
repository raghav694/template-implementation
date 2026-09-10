import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/router/pending_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => PendingRoute.location = null);

  group('RoutePaths.absolute', () {
    test('leaves in-app paths starting with / unchanged', () {
      expect(RoutePaths.absolute('/paywall'), RoutePaths.paywall);
      expect(
        RoutePaths.absolute('/paywall?planId=yearly'),
        '/paywall?planId=yearly',
      );
    });

    test('prefixes a leading slash on relative locations', () {
      expect(RoutePaths.absolute('paywall'), RoutePaths.paywall);
      expect(
        RoutePaths.absolute('paywall?planId=yearly'),
        '/paywall?planId=yearly',
      );
      expect(RoutePaths.absolute('profile'), RoutePaths.profile);
    });

    test('treats empty as home', () {
      expect(RoutePaths.absolute(''), RoutePaths.home);
      expect(RoutePaths.absolute('   '), RoutePaths.home);
    });
  });

  group('RoutePaths.isPaywall', () {
    test('matches /paywall, /paywall/:planId, and /payment', () {
      expect(RoutePaths.isPaywall('/paywall'), isTrue);
      expect(RoutePaths.isPaywall('/paywall/yearly'), isTrue);
      expect(RoutePaths.isPaywall('paywall'), isTrue);
      expect(RoutePaths.isPaywall('/payment'), isTrue);
      expect(RoutePaths.isPaywall('/profile'), isFalse);
      expect(RoutePaths.isPaywall('/'), isFalse);
    });
  });

  group('PendingRoute.stashPaywall', () {
    test('stores an absolute deeplink with a plan id', () {
      PendingRoute.stashPaywall(Uri.parse('/paywall?planId=yearly'));
      expect(PendingRoute.location, '/paywall?planId=yearly&source=DEEPLINK');
    });

    test('rewrites a custom-scheme paywall URI to an absolute in-app path', () {
      PendingRoute.stashPaywall(Uri.parse('app://paywall?planId=yearly'));
      expect(PendingRoute.location, '/paywall?planId=yearly&source=DEEPLINK');
    });

    test('normalizes a relative paywall deeplink', () {
      PendingRoute.stashPaywall(Uri.parse('paywall?planId=yearly'));
      expect(PendingRoute.location, '/paywall?planId=yearly&source=DEEPLINK');
    });

    test('stashes /payment without a plan id', () {
      PendingRoute.stashPaywall(Uri.parse('/payment?offer_type=DISCOUNT'));
      expect(
        PendingRoute.location,
        '/paywall?source=DEEPLINK&offerType=DISCOUNT',
      );
    });

    test('ignores /paywall without a plan id', () {
      PendingRoute.stashPaywall(Uri.parse('/paywall'));
      expect(PendingRoute.location, isNull);
    });

    test('ignores non-paywall URIs', () {
      PendingRoute.stashPaywall(Uri.parse('/profile'));
      expect(PendingRoute.location, isNull);
    });

    test('take() returns an absolute path and clears the stash', () {
      PendingRoute.location = 'paywall?planId=yearly';
      expect(PendingRoute.take(), '/paywall?planId=yearly');
      expect(PendingRoute.location, isNull);
    });
  });
}
