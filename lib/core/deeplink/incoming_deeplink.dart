import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/deeplink/offer_type.dart';

/// Turns an incoming URI into an in-app location.
///
/// Payment / plans / paywall links become `/paywall?planId=&offerType=&source=`.
class IncomingDeeplink {
  IncomingDeeplink._();

  static const planQueryKeys = ['planId', 'plan_id', 'plan', 'plan_price_id'];

  static const _paymentHosts = {'paywall', 'payment', 'plans'};
  static const _paymentSegments = {'paywall', 'payment', 'plans'};

  static bool isPaymentFlow(Uri uri) {
    if (_paymentHosts.contains(uri.host.toLowerCase())) return true;
    return uri.pathSegments.any(
      (segment) => _paymentSegments.contains(segment.toLowerCase()),
    );
  }

  static String? planIdFrom(Uri uri) {
    if (!isPaymentFlow(uri)) return null;

    for (final key in planQueryKeys) {
      final value = uri.queryParameters[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    for (var i = 0; i < segments.length; i++) {
      if (_paymentSegments.contains(segments[i].toLowerCase()) &&
          i + 1 < segments.length) {
        final id = segments[i + 1].trim();
        if (id.isNotEmpty) return id;
      }
    }

    if (_paymentHosts.contains(uri.host.toLowerCase()) && segments.isNotEmpty) {
      final id = segments.first.trim();
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  static OfferType? offerTypeFrom(Uri uri) {
    return OfferType.tryParse(
      uri.queryParameters['offer_type'] ??
          uri.queryParameters['offerType'] ??
          uri.queryParameters['offer'],
    );
  }

  /// Campaign / recharge source. Frontend defaults payment links to `DEEPLINK`.
  static String sourceFrom(Uri uri) {
    final raw = uri.queryParameters['source']?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'DEEPLINK';
  }

  /// `lbaType` is the frontend conversion skip — do not open checkout/paywall.
  static bool skipsPaywall(Uri uri) {
    final value = uri.queryParameters['lbaType']?.trim();
    return value != null && value.isNotEmpty;
  }

  /// Absolute in-app location, or null if this URI is not ours to open.
  static String? toAppLocation(Uri uri) {
    if (!isPaymentFlow(uri)) {
      final path = uri.path.isEmpty
          ? '/'
          : (uri.path.startsWith('/') ? uri.path : '/${uri.path}');
      if (path == RoutePaths.home ||
          path == '/home' ||
          path == RoutePaths.profile) {
        return path == '/home' ? RoutePaths.home : path;
      }
      return null;
    }

    if (skipsPaywall(uri)) return null;

    final params = <String, String>{};
    final planId = planIdFrom(uri);
    if (planId != null) params['planId'] = planId;
    params['source'] = sourceFrom(uri);
    final offer = offerTypeFrom(uri);
    if (offer != null) params['offerType'] = offer.apiValue;
    return Uri(path: RoutePaths.paywall, queryParameters: params).toString();
  }
}
