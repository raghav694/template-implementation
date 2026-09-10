import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/analytics/multi_analytics_service.dart';
import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/router/app_router.dart';
import 'package:app_template/core/router/pending_route.dart';
import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/features/analytics/pending_events_service.dart';
import 'package:app_template/features/analytics/pending_purchase_cache.dart';
import 'package:app_template/features/analytics/purchase_success_reporter.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/auth/domain/usecases/auth_usecases.dart';
import 'package:app_template/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'package:app_template/features/paywall/presentation/bloc/entitlement_cubit.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/usecases/resolve_paywall_plan.dart';
import 'package:app_template/features/paywall/domain/usecases/subscription_usecases.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_checkout_cubit.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_plan_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_pending_events_datasource.dart';
import 'fakes/fake_paywall_config.dart';
import 'fakes/fake_plan_repository.dart';
import 'fakes/fake_subscription_repository.dart';
import 'fakes/fake_truecaller_oauth_client.dart';

const _testEnv = '''
MIXPANEL_TOKEN=
USE_FIREBASE_EMULATORS=false
FIREBASE_EMULATOR_HOST=127.0.0.1
FIREBASE_FUNCTIONS_REGION=asia-south1
API_BASE_URL=https://dev-api.example.com
''';

void _registerPaywallCubit() {
  getIt.registerSingleton(
    PaywallPlanCubit(
      ResolvePaywallPlanUseCase(
        repository: FakePlanRepository(
          plans: const [
            Plan(
              id: 'yearly',
              label: 'Yearly',
              priceAmount: 999,
              billingCycle: 'year',
            ),
            Plan(
              id: 'monthly',
              label: 'Monthly',
              priceAmount: 149,
              billingCycle: 'month',
            ),
          ],
        ),
        config: FakePaywallConfig(),
      ),
    ),
  );
}

void main() {
  late AsyncValue<User?> authState;
  bool? entitlementPremium;
  bool? entitlementHasPurchased;
  var entitlementLoading = false;

  setUp(() async {
    PendingRoute.location = null;
    entitlementPremium = null;
    entitlementHasPurchased = null;
    entitlementLoading = false;
    AppConfig.resetForTesting();
    await AppConfig.initializeForTest(Environment.dev, envContent: _testEnv);
    await getIt.reset();
    getIt.registerSingleton<AnalyticsService>(MultiAnalyticsService(const []));
    getIt.registerSingleton(
      PaywallCheckoutCubit(
        analytics: getIt(),
        purchaseReporter: PurchaseSuccessReporter(
          PendingPurchaseCache(),
          getIt(),
        ),
        pendingEvents: PendingEventsService(
          FakePendingEventsDataSource(),
          getIt(),
        ),
        getSubscription: GetSubscriptionUseCase(FakeSubscriptionRepository()),
      ),
    );
    _registerPaywallCubit();
  });

  tearDown(() async {
    PendingRoute.location = null;
    await getIt.reset();
    AppConfig.resetForTesting();
  });

  GoRouter buildRouter() {
    return createAppRouter(
      redirect: (context, state) => appRedirect(
        authState: authState,
        entitlementPremium: entitlementPremium,
        entitlementHasPurchased: entitlementHasPurchased,
        entitlementLoading: entitlementLoading,
        state: state,
      ),
    );
  }

  Future<GoRouter> pumpRouter(WidgetTester tester) async {
    final router = buildRouter();
    final fakeAuth = FakeAuthRepository();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(WatchAuthStateUseCase(fakeAuth)),
          ),
          BlocProvider(create: (_) => EntitlementCubit()),
          BlocProvider(
            create: (_) => PhoneAuthBloc(
              sendPhoneOtp: SendPhoneOtpUseCase(fakeAuth),
              verifyPhoneOtp: VerifyPhoneOtpUseCase(fakeAuth),
              verifyTruecaller: VerifyTruecallerLoginUseCase(fakeAuth),
              truecallerOAuth: FakeTruecallerOAuthClient(),
              analytics: getIt(),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return router;
  }

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  const premiumUser = User(
    id: 'test-user',
    phone: '+919876543210',
    entitlement: 'premium',
    hasPurchased: true,
  );
  const newUser = User(
    id: 'test-user',
    phone: '+919876543210',
    entitlement: 'free',
  );
  const lapsedUser = User(
    id: 'test-user',
    phone: '+919876543210',
    entitlement: 'free',
    hasPurchased: true,
  );

  testWidgets('holds at /loading while the auth stream is resolving', (
    tester,
  ) async {
    authState = const AsyncLoading<User?>();
    final router = await pumpRouter(tester);
    expect(locationOf(router), RoutePaths.loading);
  });

  testWidgets('redirects unauthenticated users to /auth', (tester) async {
    authState = const AsyncData<User?>(null);
    final router = await pumpRouter(tester);
    expect(locationOf(router), RoutePaths.auth);
  });

  testWidgets('sends premium users to /home', (tester) async {
    authState = const AsyncData(premiumUser);
    final router = await pumpRouter(tester);
    expect(locationOf(router), RoutePaths.home);
  });

  testWidgets('sends first-time free users to /paywall?source=init', (
    tester,
  ) async {
    authState = const AsyncData(newUser);
    final router = await pumpRouter(tester);
    expect(locationOf(router), '/paywall?source=init');
  });

  testWidgets('sends lapsed users to /paywall?source=renewal', (tester) async {
    authState = const AsyncData(lapsedUser);
    final router = await pumpRouter(tester);
    expect(locationOf(router), '/paywall?source=renewal');
  });

  testWidgets('expire on resume sends a lapsed user from home to renewal', (
    tester,
  ) async {
    authState = const AsyncData(premiumUser);
    final router = await pumpRouter(tester);
    expect(locationOf(router), RoutePaths.home);

    authState = const AsyncData(lapsedUser);
    router.refresh();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(locationOf(router), '/paywall?source=renewal');
  });

  testWidgets(
    'sends a profile-premium user to renewal when validity has ended',
    (tester) async {
      authState = const AsyncData(premiumUser);
      entitlementPremium = false;
      entitlementHasPurchased = true;
      final router = await pumpRouter(tester);
      expect(locationOf(router), '/paywall?source=renewal');
    },
  );

  testWidgets('holds at /loading while entitlement is resolving after login', (
    tester,
  ) async {
    authState = const AsyncData(newUser);
    entitlementLoading = true;
    final router = await pumpRouter(tester);
    expect(locationOf(router), RoutePaths.loading);
  });

  testWidgets(
    'lets a premium user stay on /paywall?source=renew to re-checkout',
    (tester) async {
      authState = const AsyncData(premiumUser);
      entitlementPremium = true;
      final router = await pumpRouter(tester);
      expect(locationOf(router), RoutePaths.home);

      router.go(RoutePaths.paywallRenew);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(locationOf(router), RoutePaths.paywallRenew);
    },
  );

  testWidgets('sends a premium user from /paywall?source=renewal to /home', (
    tester,
  ) async {
    authState = const AsyncData(premiumUser);
    entitlementPremium = true;
    final router = await pumpRouter(tester);
    router.go('/paywall?source=renewal');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(locationOf(router), RoutePaths.home);
  });

  testWidgets('sends a premium user from /paywall?source=init to /home', (
    tester,
  ) async {
    authState = const AsyncData(premiumUser);
    entitlementPremium = true;
    final router = await pumpRouter(tester);
    router.go('/paywall?source=init');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(locationOf(router), RoutePaths.home);
  });

  testWidgets('signing out from inside the app redirects back to /auth', (
    tester,
  ) async {
    authState = const AsyncData(premiumUser);
    final router = await pumpRouter(tester);
    expect(locationOf(router), RoutePaths.home);

    authState = const AsyncData<User?>(null);
    router.refresh();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(locationOf(router), RoutePaths.auth);
  });

  testWidgets('after sign-in, restores a paywall deeplink plan id', (
    tester,
  ) async {
    PendingRoute.location = '/paywall?planId=yearly';
    authState = const AsyncData(premiumUser);
    final router = await pumpRouter(tester);
    expect(locationOf(router), '/paywall?planId=yearly');
  });

  testWidgets('normalizes a relative pending paywall path after sign-in', (
    tester,
  ) async {
    PendingRoute.location = 'paywall?planId=yearly';
    authState = const AsyncData(premiumUser);
    final router = await pumpRouter(tester);
    expect(locationOf(router), '/paywall?planId=yearly');
  });

  testWidgets('does not sit on /paywall while auth is loading', (tester) async {
    authState = const AsyncLoading<User?>();
    final router = await pumpRouter(tester);
    router.go('/paywall?planId=yearly');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(locationOf(router), RoutePaths.loading);
    expect(PendingRoute.location, '/paywall?planId=yearly&source=DEEPLINK');
  });

  testWidgets('does not restore a plan-less /paywall after login', (
    tester,
  ) async {
    authState = const AsyncData<User?>(null);
    final router = await pumpRouter(tester);
    router.go(RoutePaths.paywall);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(locationOf(router), RoutePaths.auth);
    expect(PendingRoute.location, isNull);

    authState = const AsyncData(premiumUser);
    router.refresh();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(locationOf(router), RoutePaths.home);
  });
}
