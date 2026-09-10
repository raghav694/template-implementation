import 'dart:async';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/attribution/attribution_store.dart';
import 'package:app_template/core/attribution/play_install_referrer_parser.dart';
import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/deeplink/deeplink_config.dart';
import 'package:app_template/core/deeplink/deeplink_resolver.dart';
import 'package:app_template/core/deeplink/incoming_deeplink.dart';
import 'package:app_template/core/deeplink/incoming_link_source.dart';
import 'package:app_template/core/deeplink/play_install_referrer_reader.dart';
import 'package:app_template/core/growthbook/growthbook_service.dart';
import 'package:app_template/core/logging/app_log.dart';
import 'package:app_template/core/router/pending_route.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Listens for app links and Play Install Referrer, saves UTM, expands short
/// links, and opens the payment / paywall flow.
class DeeplinkController {
  DeeplinkController({
    required IncomingLinkSource links,
    required GoRouter router,
    required AttributionStore attribution,
    required AnalyticsService analytics,
    required DeeplinkResolver resolver,
    PlayInstallReferrerReader? playReferrer,
    GrowthBookService? growthBook,
  }) : _links = links,
       _router = router,
       _attribution = attribution,
       _analytics = analytics,
       _resolver = resolver,
       _playReferrer = playReferrer ?? PlayInstallReferrerReaderImpl(),
       _growthBook = growthBook;

  final IncomingLinkSource _links;
  final GoRouter _router;
  final AttributionStore _attribution;
  final AnalyticsService _analytics;
  final DeeplinkResolver _resolver;
  final PlayInstallReferrerReader _playReferrer;
  final GrowthBookService? _growthBook;

  StreamSubscription<Uri>? _subscription;
  var _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _attribution.hydrate();
    _pushAttributionToGrowthBook();
    await _capturePlayInstallReferrer();
    try {
      final initial = await _links.getInitialLink();
      if (initial != null) {
        await handle(initial);
      }
    } catch (error, stackTrace) {
      AppLog.e('Initial deeplink failed', error, stackTrace);
    }
    _subscription = _links.uriLinkStream.listen(
      (uri) => unawaited(handle(uri)),
      onError: (Object error, StackTrace stackTrace) {
        AppLog.e('Deeplink stream failed', error, stackTrace);
      },
    );
  }

  @visibleForTesting
  Future<void> capturePlayInstallReferrerForTest() {
    return _capturePlayInstallReferrer();
  }

  Future<void> handle(Uri link) async {
    AppLog.d('Deeplink received: $link');
    await _analytics.logEvent(
      AnalyticsEvents.receivedDeeplink,
      parameters: {AnalyticsProperties.deeplink: link.toString()},
    );
    await _attribution.saveFromUri(link);
    _pushAttributionToGrowthBook();
    _maybeCountFacebookRetarget(link);

    var resolved = link;
    if (DeeplinkConfig.needsResolve(link)) {
      final original = await _resolver.resolve(link: link.toString());
      if (original != null) {
        resolved = original;
        await _analytics.logEvent(
          AnalyticsEvents.resolvedDeeplink,
          parameters: {AnalyticsProperties.deeplink: original.toString()},
        );
        await _attribution.saveFromUri(original);
        _pushAttributionToGrowthBook();
      }
    }

    _open(resolved);
  }

  Future<void> _capturePlayInstallReferrer() async {
    try {
      final referrer = await _playReferrer.read();
      if (referrer == null || referrer.isEmpty) return;

      final consumed = await _attribution.consumePlayReferrer();
      if (!consumed) return;

      AppLog.d('Install referrer: $referrer');
      final params = parseInstallReferrer(referrer);
      await _attribution.saveFromReferrerParams(params);
      _pushAttributionToGrowthBook();

      final shortId = params['short_id']?.trim();
      if (shortId == null || shortId.isEmpty) return;

      final original = await _resolver.resolve(shortId: shortId);
      if (original == null) return;

      await _analytics.logEvent(
        AnalyticsEvents.resolvedDeeplink,
        parameters: {AnalyticsProperties.deeplink: original.toString()},
      );
      await _attribution.saveFromUri(original);
      _pushAttributionToGrowthBook();
      _open(original);
    } catch (error, stackTrace) {
      AppLog.e('Play Install Referrer failed', error, stackTrace);
    }
  }

  void _pushAttributionToGrowthBook() {
    _growthBook?.applyAttribution(_attribution.data);
  }

  void _open(Uri uri) {
    final location = IncomingDeeplink.toAppLocation(uri);
    if (location == null) return;
    PendingRoute.stashIncoming(uri);
    _router.go(RoutePaths.absolute(location));
  }

  void _maybeCountFacebookRetarget(Uri uri) {
    final source =
        (uri.queryParameters['utm_source'] ??
                uri.queryParameters['utmSource'] ??
                '')
            .toLowerCase();
    if (source.contains('fb') || source.contains('facebook')) {
      unawaited(_analytics.incrementUserProperty('retargetCount'));
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
