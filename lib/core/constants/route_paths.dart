import 'package:app_template/core/constants/paywall_sources.dart';

class RoutePaths {
  RoutePaths._();

  /// Internal gate screen shown while auth resolves on first load.
  static const loading = '/loading';

  static const home = '/';
  static const profile = '/profile';
  static const paymentSettings = '/payment-settings';
  static const auth = '/auth';
  static const paywall = '/paywall';

  /// Incoming payment deeplink. Redirects to [paywall] with plan/offer query.
  static const payment = '/payment';

  static const paywallSourceQuery = 'source';

  /// Cancelled-but-still-premium checkout from Payment settings (Vokey).
  static String get paywallRenew =>
      '$paywall?$paywallSourceQuery=${PaywallSources.renew}';

  /// Always an in-app path beginning with `/`. Relative locations like
  /// `paywall` are rewritten so go_router cannot nest them under the
  /// current route (e.g. `/paywall/profile`).
  static String absolute(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return home;
    final uri = Uri.parse(trimmed);
    final path = uri.path.isEmpty
        ? home
        : (uri.path.startsWith('/') ? uri.path : '/${uri.path}');
    if (uri.hasQuery || uri.hasFragment) {
      return uri.replace(path: path).toString();
    }
    return path;
  }

  static bool isPaywall(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    final normalized = absolute(path);
    return normalized == payment ||
        normalized.startsWith('$payment/') ||
        normalized == paywall ||
        normalized.startsWith('$paywall/');
  }

  static String paywallFor({String? planId}) {
    final id = planId?.trim();
    if (id == null || id.isEmpty) return paywall;
    return '$paywall/$id';
  }
}

class RouteNames {
  RouteNames._();

  static const home = 'home';
  static const profile = 'profile';
  static const paymentSettings = 'paymentSettings';
  static const auth = 'auth';
  static const paywall = 'paywall';
  static const paywallPlan = 'paywallPlan';
}
