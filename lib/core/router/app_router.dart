import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/config/app_identity.dart';
import 'package:app_template/core/app_update/ios_store_upgrade_gate.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/auth/presentation/screens/auth_screen.dart';
import 'package:app_template/features/home/presentation/screens/home_screen.dart';
import 'package:app_template/features/paywall/presentation/screens/payment_settings_screen.dart';
import 'package:app_template/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:app_template/features/profile/presentation/screens/profile_screen.dart';
import 'package:app_template/shared/widgets/route_not_found_screen.dart';
import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/constants/paywall_sources.dart';
import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/utils/page_transitions.dart';
import 'package:app_template/core/deeplink/incoming_deeplink.dart';
import 'package:app_template/core/router/pending_route.dart';

GoRouter createAppRouter({
  List<NavigatorObserver> observers = const [],
  Listenable? refreshListenable,
  String? Function(BuildContext context, GoRouterState state)? redirect,
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.loading,
    debugLogDiagnostics: true,
    observers: observers,
    refreshListenable: refreshListenable,
    redirect: redirect,
    routes: [
      GoRoute(
        path: RoutePaths.loading,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AppLoadingScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.auth,
        name: RouteNames.auth,
        pageBuilder: (context, state) => FadeSlidePage<void>(
          key: state.pageKey,
          name: state.name,
          child: const AuthScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => FadeSlidePage<void>(
          key: state.pageKey,
          name: state.name,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.paymentSettings,
        name: RouteNames.paymentSettings,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => FadeSlidePage<void>(
          key: state.pageKey,
          name: state.name,
          child: const PaymentSettingsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.payment,
        redirect: (context, state) =>
            IncomingDeeplink.toAppLocation(state.uri) ??
            '${RoutePaths.paywall}?source=DEEPLINK',
      ),
      GoRoute(
        path: RoutePaths.paywall,
        name: RouteNames.paywall,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => FadeSlidePage<void>(
          key: state.pageKey,
          name: state.name,
          child: PaywallScreen.fromRoute(state),
        ),
      ),
      GoRoute(
        path: '${RoutePaths.paywall}/:planId',
        name: RouteNames.paywallPlan,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => FadeSlidePage<void>(
          key: state.pageKey,
          name: state.name,
          child: PaywallScreen.fromRoute(state),
        ),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        pageBuilder: (context, state) => FadeSlidePage<void>(
          key: state.pageKey,
          name: state.name,
          child: const IosStoreUpgradeGate(child: HomeScreen()),
        ),
      ),
    ],
    errorBuilder: (context, state) =>
        RouteNotFoundScreen(location: state.uri.toString()),
  );
}

/// Guards every navigation in the app.
///
/// 1. Auth loading — hold at `/loading`.
/// 2. Not authenticated — redirect to `/auth` (paywall deeplinks are stashed).
/// 3. Authenticated + entitlement loading — hold at `/loading` (Vokey) so
///    Capslock `validity_end_at` can overlay profile before Home/paywall.
/// 4. Authenticated + premium — enter the app; restore a stashed paywall link.
///    `/paywall?source=renew` stays so cancelled Autopay can re-checkout.
/// 5. Authenticated + free — `/paywall?source=init` or `source=renewal`.
///
/// [entitlementPremium] overlays Capslock `validity_end_at`. A past end date
/// sends the user to renewal even if profile `entitlement` is still premium.
/// Pass null while entitlement is still loading so profile access is used
/// only after the first Capslock fetch (or when payments are not configured).
String? appRedirect({
  required AsyncValue<User?> authState,
  required GoRouterState state,
  bool? entitlementPremium,
  bool? entitlementHasPurchased,
  bool entitlementLoading = false,
}) {
  final location = RoutePaths.absolute(state.matchedLocation);
  final isAuthRoute = location == RoutePaths.auth;
  final isLoadingRoute = location == RoutePaths.loading;
  final isPaywallRoute = RoutePaths.isPaywall(location);
  final isPaymentSettings = location == RoutePaths.paymentSettings;
  final isInsideApp =
      !isAuthRoute && !isLoadingRoute && !isPaywallRoute;

  if (authState.isLoading) {
    PendingRoute.stashPaywall(state.uri);
    // Do not render /paywall until auth is known. Sitting there starts a
    // plans API fetch that can hang, and looks like a stuck paywall.
    if (isPaywallRoute) return RoutePaths.loading;
    if (isInsideApp) return null;
    return isLoadingRoute ? null : RoutePaths.loading;
  }

  final user = authState.maybeWhen(
    data: (value) => value,
    orElse: () => null,
  );
  if (user == null) {
    PendingRoute.stashPaywall(state.uri);
    return isAuthRoute ? null : RoutePaths.auth;
  }

  if (entitlementLoading) {
    if (isInsideApp || isPaywallRoute) return null;
    return isLoadingRoute ? null : RoutePaths.loading;
  }

  final access = (
    isPremium: entitlementPremium ?? user.isPremium,
    hasPurchased: entitlementHasPurchased ?? user.hasPurchased,
  );

  if (isPaywallRoute) {
    PendingRoute.location = null;
    final source = state.uri.queryParameters[RoutePaths.paywallSourceQuery];
    if (access.isPremium && PaywallSources.isInit(source)) {
      return RoutePaths.home;
    }
    if (access.isPremium && PaywallSources.isLapsed(source)) {
      return RoutePaths.home;
    }
    return null;
  }

  if (isAuthRoute || isLoadingRoute) {
    return PendingRoute.take() ?? _homeOrGatedPaywall(access);
  }

  if (!access.isPremium && !isPaymentSettings) {
    return _homeOrGatedPaywall(access);
  }

  return null;
}

String _homeOrGatedPaywall(({bool isPremium, bool hasPurchased}) access) {
  if (access.isPremium) return RoutePaths.home;
  return access.hasPurchased
      ? '${RoutePaths.paywall}?source=${PaywallSources.renewal}'
      : '${RoutePaths.paywall}?source=${PaywallSources.init}';
}

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> {
  static bool _loggedThisSession = false;
  static bool _firstAppOpenAttempted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analytics = getIt<AnalyticsService>();
    if (!_loggedThisSession) {
      _loggedThisSession = true;
      analytics.logEvent(AnalyticsEvents.splashScreen);
    }
    if (!_firstAppOpenAttempted) {
      _firstAppOpenAttempted = true;
      unawaited(_logFirstAppOpenOnce(analytics));
    }
  }

  Future<void> _logFirstAppOpenOnce(AnalyticsService analytics) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'analytics_first_app_open_logged';
    if (prefs.getBool(key) ?? false) return;
    analytics.logEvent(AnalyticsEvents.firstAppOpen);
    await prefs.setBool(key, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppIdentity.appName.startsWith('__')
                  ? 'App'
                  : AppIdentity.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
