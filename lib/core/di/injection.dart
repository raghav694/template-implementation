import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:app_template/features/analytics/data/events_api_service.dart';
import 'package:app_template/features/analytics/data/pending_events_datasource_impl.dart';
import 'package:app_template/features/analytics/pending_events_service.dart';
import 'package:app_template/features/analytics/pending_purchase_cache.dart';
import 'package:app_template/features/analytics/purchase_success_reporter.dart';
import 'package:app_template/features/auth/data/datasources/auth_api_service.dart';
import 'package:app_template/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:app_template/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app_template/features/auth/data/truecaller_oauth_client_impl.dart';
import 'package:app_template/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_template/features/auth/domain/truecaller_oauth_client.dart';
import 'package:app_template/features/auth/domain/usecases/auth_usecases.dart';
import 'package:app_template/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'package:app_template/features/auth/presentation/bloc/sign_out_cubit.dart';
import 'package:app_template/features/notifications/presentation/bloc/foreground_notification_cubit.dart';
import 'package:app_template/features/notifications/presentation/bloc/pending_notification_cubit.dart';
import 'package:app_template/features/notifications/presentation/bloc/push_notification_service.dart';
import 'package:app_template/features/paywall/data/datasources/paywall_config_impl.dart';
import 'package:app_template/features/paywall/data/datasources/plan_remote_datasource_impl.dart';
import 'package:app_template/features/paywall/data/datasources/subscription_remote_datasource.dart';
import 'package:app_template/features/paywall/data/datasources/subscription_remote_datasource_impl.dart';
import 'package:app_template/features/paywall/data/repositories/plan_repository_impl.dart';
import 'package:app_template/features/paywall/data/repositories/subscription_repository_impl.dart';
import 'package:app_template/features/paywall/domain/repositories/paywall_config.dart';
import 'package:app_template/features/paywall/domain/repositories/plan_repository.dart';
import 'package:app_template/features/paywall/domain/repositories/subscription_repository.dart';
import 'package:app_template/features/paywall/domain/usecases/resolve_paywall_plan.dart';
import 'package:app_template/features/paywall/domain/usecases/subscription_usecases.dart';
import 'package:app_template/features/paywall/presentation/bloc/entitlement_cubit.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_checkout_cubit.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_plan_cubit.dart';
import 'package:app_template/core/app_update/app_config_status_source.dart';
import 'package:app_template/core/app_update/app_config_status_source_impl.dart';
import 'package:app_template/core/app_update/app_update_service.dart';
import 'package:app_template/core/app_update/config_api_service.dart';
import 'package:app_template/core/app_update/merged_app_config_status_source.dart';
import 'package:app_template/core/app_update/play_in_app_updater.dart';
import 'package:app_template/core/app_update/remote_config_app_config_status_source.dart';
import 'package:app_template/core/analytics/analytics_factory.dart';
import 'package:app_template/core/analytics/analytics_route_observer.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/attribution/attribution_store.dart';
import 'package:app_template/core/deeplink/deeplink_api_service.dart';
import 'package:app_template/core/deeplink/deeplink_controller.dart';
import 'package:app_template/core/deeplink/deeplink_resolver.dart';
import 'package:app_template/core/deeplink/incoming_link_source.dart';
import 'package:app_template/core/deeplink/play_install_referrer_reader.dart';
import 'package:app_template/core/deeplink/deeplink_resolver_impl.dart';
import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/growthbook/growthbook_service.dart';
import 'package:app_template/core/network/app_api_client.dart';
import 'package:app_template/core/network/auth_token_store.dart';
import 'package:app_template/core/network/rest_session.dart';
import 'package:app_template/core/payments/capslock_http_sender.dart';
import 'package:app_template/core/router/app_router.dart';
import 'package:app_template/core/router/go_router_refresh_stream.dart';

final GetIt getIt = GetIt.instance;

/// Registers the app graph. Call once after flavor [AppConfig] is loaded.
Future<void> configureDependencies({AuthRepository? authRepository}) async {
  await getIt.reset();

  getIt
    ..registerLazySingleton<AuthTokenStore>(AuthTokenStore.new)
    ..registerLazySingleton<RestSession>(RestSession.new)
    ..registerLazySingleton<AppApiClient>(
      () => AppApiClient(tokenStore: getIt(), session: getIt()),
    )
    ..registerLazySingleton<AuthApiService>(
      () => AuthApiService(getIt<AppApiClient>().authDio),
    )
    ..registerLazySingleton<EventsApiService>(
      () => EventsApiService(getIt<AppApiClient>().dio),
    )
    ..registerLazySingleton<DeeplinkApiService>(
      () => DeeplinkApiService(getIt<AppApiClient>().dio),
    )
    ..registerLazySingleton<ConfigApiService>(
      () => ConfigApiService(getIt<AppApiClient>().dio),
    )
    ..registerLazySingleton<AuthRepository>(
      () =>
          authRepository ??
          AuthRepositoryImpl(
            AuthRemoteDataSourceImpl(
              authApi: getIt(),
              client: getIt(),
              tokenStore: getIt(),
              session: getIt(),
            ),
          ),
    )
    ..registerLazySingleton<AnalyticsService>(createAnalyticsService)
    ..registerLazySingleton(AttributionStore.new)
    ..registerLazySingleton(GrowthBookService.new)
    ..registerLazySingleton<DeeplinkResolver>(
      () => DeeplinkResolverImpl(
        getIt<DeeplinkApiService>(),
        getIt<AppApiClient>(),
      ),
    )
    ..registerLazySingleton<IncomingLinkSource>(IncomingLinkSourceImpl.new)
    ..registerLazySingleton<PlayInstallReferrerReader>(
      PlayInstallReferrerReaderImpl.new,
    )
    ..registerLazySingleton(PendingPurchaseCache.new)
    ..registerLazySingleton(() => PurchaseSuccessReporter(getIt(), getIt()))
    ..registerLazySingleton(
      () => PendingEventsService(
        PendingEventsDataSourceImpl(
          getIt<EventsApiService>(),
          getIt<AppApiClient>(),
        ),
        getIt(),
        cache: getIt(),
      ),
    )
    ..registerLazySingleton(() => WatchAuthStateUseCase(getIt()))
    ..registerLazySingleton(() => SendPhoneOtpUseCase(getIt()))
    ..registerLazySingleton(() => VerifyPhoneOtpUseCase(getIt()))
    ..registerLazySingleton(() => VerifyTruecallerLoginUseCase(getIt()))
    ..registerLazySingleton(() => SignOutUseCase(getIt()))
    ..registerLazySingleton(() => GetCurrentUserUseCase(getIt()))
    ..registerLazySingleton<TruecallerOAuthClient>(
      TruecallerOAuthClientImpl.new,
    )
    ..registerLazySingleton<AuthCubit>(
      () => AuthCubit(getIt(), getCurrentUser: getIt()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<PhoneAuthBloc>(
      () => PhoneAuthBloc(
        sendPhoneOtp: getIt(),
        verifyPhoneOtp: getIt(),
        verifyTruecaller: getIt(),
        truecallerOAuth: getIt(),
        analytics: getIt(),
      ),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<SignOutCubit>(
      () => SignOutCubit(
        signOutUseCase: getIt(),
        analytics: getIt(),
        phoneAuthBloc: getIt(),
      ),
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<ForegroundNotificationCubit>(
      ForegroundNotificationCubit.new,
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<PendingNotificationCubit>(
      PendingNotificationCubit.new,
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<PushNotificationService>(
      () => PushNotificationService(
        authCubit: getIt(),
        foreground: getIt(),
        pendingNavigation: getIt(),
      ),
      dispose: (service) => service.dispose(),
    )
    ..registerLazySingleton<AppConfigStatusSource>(
      () => MergedAppConfigStatusSource(
        remoteConfig: const RemoteConfigAppConfigStatusSource(),
        api: AppConfigStatusSourceImpl(
          getIt<ConfigApiService>(),
          getIt<AppApiClient>(),
        ),
      ),
    )
    ..registerLazySingleton<PlayInAppUpdater>(PlayInAppUpdaterImpl.new)
    ..registerLazySingleton<AppUpdateService>(
      () => AppUpdateService(
        statusSource: getIt(),
        playUpdater: getIt(),
        growthBook: getIt(),
      ),
      dispose: (service) => service.dispose(),
    )
    ..registerLazySingleton<CheckoutClient>(
      () => CheckoutClient(
        HttpCheckoutTransport(
          baseUrl: AppConfig.paymentsBaseUrl,
          sender: CapslockHttpSender.send,
        ),
      ),
    )
    ..registerLazySingleton<PaywallConfig>(
      () => PaywallConfigImpl(growthBook: getIt()),
    )
    ..registerLazySingleton<PlanRepository>(
      () =>
          PlanRepositoryImpl(PlanRemoteDataSourceImpl(getIt<CheckoutClient>())),
    )
    ..registerLazySingleton<SubscriptionRemoteDataSource>(
      () => SubscriptionRemoteDataSourceImpl(getIt<CheckoutClient>()),
    )
    ..registerLazySingleton<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => CheckEntitlementUseCase(getIt()))
    ..registerLazySingleton(() => GetSubscriptionUseCase(getIt()))
    ..registerLazySingleton(() => CancelSubscriptionUseCase(getIt()))
    ..registerLazySingleton(
      () => ResolvePaywallPlanUseCase(repository: getIt(), config: getIt()),
    )
    ..registerLazySingleton<EntitlementCubit>(
      () => EntitlementCubit(
        analytics: getIt(),
        purchaseReporter: getIt(),
        growthBook: getIt(),
        getSubscription: getIt(),
      ),
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<PaywallPlanCubit>(
      () => PaywallPlanCubit(getIt()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<PaywallCheckoutCubit>(
      () => PaywallCheckoutCubit(
        analytics: getIt(),
        purchaseReporter: getIt(),
        pendingEvents: getIt(),
        getSubscription: getIt(),
      ),
      dispose: (cubit) => cubit.close(),
    )
    ..registerLazySingleton<GoRouterRefreshStream>(
      () => GoRouterRefreshStream([
        getIt<AuthCubit>().stream,
        getIt<EntitlementCubit>().stream,
      ]),
      dispose: (refresh) => refresh.dispose(),
    )
    ..registerLazySingleton<GoRouter>(
      () => createAppRouter(
        refreshListenable: getIt<GoRouterRefreshStream>(),
        redirect: (context, state) {
          final entitlement = getIt<EntitlementCubit>().state.valueOrNull;
          return appRedirect(
            authState: getIt<AuthCubit>().state,
            entitlementPremium: entitlement?.isPremium,
            entitlementHasPurchased: entitlement?.hasPurchased,
            entitlementLoading: getIt<EntitlementCubit>().state.isLoading,
            state: state,
          );
        },
        observers: [AnalyticsRouteObserver(getIt())],
      ),
      dispose: (router) => router.dispose(),
    )
    ..registerLazySingleton<DeeplinkController>(
      () => DeeplinkController(
        links: getIt(),
        router: getIt(),
        attribution: getIt(),
        analytics: getIt(),
        resolver: getIt(),
        playReferrer: getIt(),
        growthBook: getIt(),
      ),
      dispose: (controller) => controller.dispose(),
    );

  getIt<AuthCubit>();
  getIt<GoRouter>();
  getIt<PushNotificationService>().start();
}
