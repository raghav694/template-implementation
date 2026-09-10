import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/deeplink/incoming_deeplink.dart';

/// Holds an in-app location across the auth/loading gate so a paywall /
/// payment deeplink survives sign-in.
///
/// Stored locations always start with `/`. A relative `paywall` would
/// otherwise resolve under `/auth` or `/loading`.
class PendingRoute {
  PendingRoute._();

  static String? location;

  static void stashIncoming(Uri uri) {
    final appLocation = IncomingDeeplink.toAppLocation(uri);
    if (appLocation == null) return;
    location = RoutePaths.absolute(appLocation);
  }

  /// Stashes a payment / paywall deeplink. In-app `/paywall` with no plan
  /// or offer is ignored so Plans → login does not bounce back.
  static void stashPaywall(Uri uri) {
    if (!IncomingDeeplink.isPaymentFlow(uri)) return;
    final hasPlan = IncomingDeeplink.planIdFrom(uri) != null;
    final hasOffer = IncomingDeeplink.offerTypeFrom(uri) != null;
    final isPaymentPath =
        uri.host.toLowerCase() == 'payment' ||
        uri.pathSegments.any((segment) => segment.toLowerCase() == 'payment');
    if (!hasPlan && !hasOffer && !isPaymentPath) return;
    stashIncoming(uri);
  }

  static String? take() {
    final pending = location;
    location = null;
    if (pending == null || pending.isEmpty) return null;
    return RoutePaths.absolute(pending);
  }
}
