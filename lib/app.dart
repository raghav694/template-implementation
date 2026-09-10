import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:app_template/config/app_identity.dart';
import 'package:app_template/core/app_update/app_update_service.dart';
import 'package:app_template/core/app_update/maintenance_gate.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/attribution/attribution_store.dart';
import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/crashlytics/crashlytics_service.dart';
import 'package:app_template/core/deeplink/deeplink_controller.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/growthbook/growthbook_analytics.dart';
import 'package:app_template/core/growthbook/growthbook_service.dart';
import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/core/theme/app_theme.dart';
import 'package:app_template/features/analytics/pending_events_service.dart';
import 'package:app_template/features/analytics/purchase_success_reporter.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'package:app_template/features/auth/presentation/bloc/sign_out_cubit.dart';
import 'package:app_template/features/notifications/presentation/bloc/foreground_notification_cubit.dart';
import 'package:app_template/features/notifications/presentation/bloc/pending_notification_cubit.dart';
import 'package:app_template/features/notifications/presentation/widgets/push_notification_listener.dart';
import 'package:app_template/features/paywall/presentation/bloc/entitlement_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final title = AppIdentity.appName.startsWith('__')
        ? 'App'
        : AppIdentity.appName;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<PhoneAuthBloc>()),
        BlocProvider.value(value: getIt<SignOutCubit>()),
        BlocProvider.value(value: getIt<ForegroundNotificationCubit>()),
        BlocProvider.value(value: getIt<PendingNotificationCubit>()),
        BlocProvider.value(value: getIt<EntitlementCubit>()),
      ],
      child: BlocListener<AuthCubit, AsyncValue<User?>>(
        listener: (context, state) {
          final uid = state.valueOrNull?.id;
          if (uid != null && uid.isNotEmpty) {
            CrashlyticsService.setUserId(uid);
            unawaited(getIt<AnalyticsService>().setUserId(uid));
            final growthBook = getIt<GrowthBookService>();
            final isPremium = state.valueOrNull?.isPremium ?? false;
            growthBook.setUser(userId: uid, isPremium: isPremium);
            unawaited(() async {
              final analytics = getIt<AnalyticsService>();
              final store = getIt<AttributionStore>();
              await store.applyToAnalytics(analytics);
              growthBook.applyAttribution(store.data);
              await growthBook.prepareForPlanEvaluation(
                userId: uid,
                isPremium: isPremium,
              );
              await trackEnabledGrowthBookFeatures(
                analytics,
                growthBook,
                isInit: true,
              );
            }());
            unawaited(getIt<PendingEventsService>().processPendingEvents());
            final user = state.valueOrNull!;
            unawaited(
              getIt<EntitlementCubit>().refreshFor(
                userId: user.id,
                isPremium: user.isPremium,
                hasPurchased: user.hasPurchased,
                expiresAt: user.expiresAt,
              ),
            );
          } else {
            CrashlyticsService.clearUserId();
            getIt<EntitlementCubit>().clear();
          }
        },
        child: PushNotificationListener(
          child: _PendingEventsLifecycle(
            child: _DeeplinkLifecycle(
              child: _AppUpdateLifecycle(
                child: MaterialApp.router(
                  title: title,
                  debugShowCheckedModeBanner: AppConfig.showDebugBanner,
                  theme: AppTheme.light,
                  routerConfig: getIt<GoRouter>(),
                  builder: (context, child) =>
                      MaintenanceGate(child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Starts app-link + Play Install Referrer capture after the router exists.
class _DeeplinkLifecycle extends StatefulWidget {
  const _DeeplinkLifecycle({required this.child});

  final Widget child;

  @override
  State<_DeeplinkLifecycle> createState() => _DeeplinkLifecycleState();
}

class _DeeplinkLifecycleState extends State<_DeeplinkLifecycle> {
  @override
  void initState() {
    super.initState();
    unawaited(getIt<DeeplinkController>().start());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Drains queued payment events when the app returns to the foreground.
class _PendingEventsLifecycle extends StatefulWidget {
  const _PendingEventsLifecycle({required this.child});

  final Widget child;

  @override
  State<_PendingEventsLifecycle> createState() =>
      _PendingEventsLifecycleState();
}

class _PendingEventsLifecycleState extends State<_PendingEventsLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final user = getIt<AuthCubit>().state.valueOrNull;
    if (user == null) return;
    unawaited(getIt<AuthCubit>().refreshProfile());
    unawaited(
      getIt<EntitlementCubit>().refreshFor(
        userId: user.id,
        isPremium: user.isPremium,
        hasPurchased: user.hasPurchased,
        expiresAt: user.expiresAt,
      ),
    );
    unawaited(getIt<PendingEventsService>().processPendingEvents());
    final isPremium =
        getIt<EntitlementCubit>().state.valueOrNull?.isPremium == true;
    if (isPremium) {
      unawaited(
        getIt<PurchaseSuccessReporter>().flushOnPremiumResume(userId: user.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Play in-app update on splash + resume; refreshes force/maintenance flags.
class _AppUpdateLifecycle extends StatefulWidget {
  const _AppUpdateLifecycle({required this.child});

  final Widget child;

  @override
  State<_AppUpdateLifecycle> createState() => _AppUpdateLifecycleState();
}

class _AppUpdateLifecycleState extends State<_AppUpdateLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(getIt<AppUpdateService>().checkOnLaunch());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(getIt<AppUpdateService>().checkForceUpdate());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
