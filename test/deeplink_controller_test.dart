import 'dart:async';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/attribution/attribution_store.dart';
import 'package:app_template/core/deeplink/deeplink_controller.dart';
import 'package:app_template/core/deeplink/deeplink_resolver.dart';
import 'package:app_template/core/deeplink/incoming_link_source.dart';
import 'package:app_template/core/deeplink/play_install_referrer_reader.dart';
import 'package:app_template/core/router/pending_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_growthbook_service.dart';
import 'fakes/recording_analytics_service.dart';

class _FakeLinks implements IncomingLinkSource {
  Uri? initial;
  final controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialLink() async => initial;

  @override
  Stream<Uri> get uriLinkStream => controller.stream;
}

class _FakeResolver implements DeeplinkResolver {
  Uri? result;
  String? lastLink;
  String? lastShortId;
  var calls = 0;

  @override
  Future<Uri?> resolve({String? link, String? shortId}) async {
    calls += 1;
    lastLink = link;
    lastShortId = shortId;
    return result;
  }
}

class _FakePlayReferrer implements PlayInstallReferrerReader {
  String? value;

  @override
  Future<String?> read() async => value;
}

void main() {
  late _FakeLinks links;
  late _FakeResolver resolver;
  late _FakePlayReferrer playReferrer;
  late AttributionStore attribution;
  late RecordingAnalyticsService analytics;
  late FakeGrowthBookService growthBook;
  late GoRouter router;
  late DeeplinkController controller;

  setUp(() async {
    PendingRoute.location = null;
    SharedPreferences.setMockInitialValues({});
    links = _FakeLinks();
    resolver = _FakeResolver();
    playReferrer = _FakePlayReferrer();
    attribution = AttributionStore(
      prefs: await SharedPreferences.getInstance(),
    );
    analytics = RecordingAnalyticsService();
    growthBook = FakeGrowthBookService();
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/paywall', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/auth', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/loading', builder: (_, _) => const SizedBox()),
      ],
    );
    controller = DeeplinkController(
      links: links,
      router: router,
      attribution: attribution,
      analytics: analytics,
      resolver: resolver,
      playReferrer: playReferrer,
      growthBook: growthBook,
    );
  });

  tearDown(() async {
    await controller.dispose();
    await links.controller.close();
    PendingRoute.location = null;
  });

  testWidgets('opens paywall from a payment deeplink and stores UTM', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await controller.handle(
      Uri.parse(
        '/payment?plan_price_id=yearly&offer_type=DISCOUNT&utm_source=facebook&utm_medium=cpc',
      ),
    );
    await tester.pump();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/paywall?planId=yearly&source=DEEPLINK&offerType=DISCOUNT',
    );
    expect(attribution.data.utmSource, 'facebook');
    expect(attribution.data.utmMedium, 'cpc');
    expect(growthBook.lastAttribution?.utmSource, 'facebook');
    expect(growthBook.lastAttribution?.utmMedium, 'cpc');
    expect(
      analytics.logged.any(
        (event) => event.name == AnalyticsEvents.receivedDeeplink,
      ),
      isTrue,
    );
  });

  testWidgets('expands a short https link then opens payment', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    resolver.result = Uri.parse('/payment?planId=monthly');

    await controller.handle(Uri.parse('https://short.example/abc'));
    await tester.pump();

    expect(resolver.lastLink, 'https://short.example/abc');
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/paywall?planId=monthly&source=DEEPLINK',
    );
    expect(
      analytics.logged.any(
        (event) => event.name == AnalyticsEvents.resolvedDeeplink,
      ),
      isTrue,
    );
  });

  testWidgets('Play Install Referrer short_id is resolved once', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    playReferrer.value =
        'utm_source=google-play&utm_medium=organic&short_id=abc123';
    resolver.result = Uri.parse('/payment?planId=yearly');

    await controller.capturePlayInstallReferrerForTest();
    await tester.pump();

    expect(resolver.lastShortId, 'abc123');
    expect(attribution.data.utmSource, 'google-play');
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/paywall?planId=yearly&source=DEEPLINK',
    );

    resolver.calls = 0;
    await controller.capturePlayInstallReferrerForTest();
    expect(resolver.calls, 0);
  });
}
