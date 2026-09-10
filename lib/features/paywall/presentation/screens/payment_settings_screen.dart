import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:app_template/features/paywall/domain/entities/entitlement.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:app_template/features/paywall/domain/repositories/plan_repository.dart';
import 'package:app_template/features/paywall/domain/services/payment_event_properties.dart';
import 'package:app_template/features/paywall/domain/services/payment_settings_access.dart';
import 'package:app_template/features/paywall/domain/usecases/subscription_usecases.dart';
import 'package:app_template/features/paywall/presentation/bloc/entitlement_cubit.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_plan_cubit.dart';
import 'package:app_template/features/paywall/presentation/widgets/cancel_confirm_sheet.dart';
import 'package:app_template/features/paywall/presentation/widgets/cancel_subscription_button.dart';
import 'package:app_template/features/paywall/presentation/widgets/plan_details_card.dart';
import 'package:app_template/features/paywall/presentation/widgets/renew_subscription_button.dart';
import 'package:app_template/shared/widgets/error_state_view.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  Subscription? _subscription;
  Plan? _plan;
  Failure? _subscriptionError;
  var _loadingSubscription = true;
  var _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  String? get _userId {
    final user = context.read<AuthCubit>().state.valueOrNull;
    return user?.id;
  }

  Future<void> _reload() async {
    await context.read<AuthCubit>().refreshProfile();
    if (!mounted) return;
    final user = context.read<AuthCubit>().state.valueOrNull;
    if (user != null) {
      await context.read<EntitlementCubit>().refreshFor(
        userId: user.id,
        isPremium: user.isPremium,
        hasPurchased: user.hasPurchased,
        expiresAt: user.expiresAt,
      );
    }
    final userId = user?.id;
    if (userId == null) {
      setState(() {
        _subscription = null;
        _plan = null;
        _loadingSubscription = false;
        _subscriptionError = null;
      });
      return;
    }
    final result = await getIt<GetSubscriptionUseCase>()(
      GetSubscriptionParams(userId: userId),
    );
    if (!mounted) return;
    await result.fold(
      (_) async => setState(() {
        // One-time / lifetime often has no Capslock subscription row.
        _subscription = null;
        _plan = null;
        _subscriptionError = null;
        _loadingSubscription = false;
      }),
      (subscription) async {
        Plan? plan;
        final planId = subscription?.plan.trim() ?? '';
        if (planId.isNotEmpty) {
          final planResult = await getIt<PlanRepository>().getPlan(planId);
          plan = planResult.fold((_) => null, (value) => value);
        }
        if (!mounted) return;
        setState(() {
          _subscription = subscription;
          _plan = plan;
          _subscriptionError = null;
          _loadingSubscription = false;
        });
      },
    );
  }

  bool _canCancel(Entitlement entitlement) => PaymentSettingsAccess.canCancel(
    isPremium: entitlement.isPremium,
    isOneTime: PaymentSettingsAccess.isOneTimePlan(_plan),
    subscription: _subscription,
  );

  bool _canRenew(Entitlement entitlement) => PaymentSettingsAccess.canRenew(
    isPremium: entitlement.isPremium,
    isOneTime: PaymentSettingsAccess.isOneTimePlan(_plan),
    subscription: _subscription,
  );

  void _openRenewalPaywall() {
    HapticFeedback.lightImpact();
    final planId = _subscription?.plan.trim() ?? '';
    final cubit = getIt<PaywallPlanCubit>();
    if (planId.isNotEmpty) {
      cubit.setForcedPlanId(planId);
    } else {
      cubit.clearForcedPlanId();
    }
    context.push(RoutePaths.paywallRenew);
  }

  Future<void> _confirmCancel() async {
    HapticFeedback.lightImpact();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => const CancelConfirmSheet(),
    );
    if (confirmed != true || !mounted) return;
    final userId = _userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to cancel your subscription.')),
      );
      return;
    }
    setState(() => _cancelling = true);
    final result = await getIt<CancelSubscriptionUseCase>()(
      CancelSubscriptionParams(userId: userId),
    );
    if (!mounted) return;
    setState(() => _cancelling = false);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) async {
        final plan = _plan;
        final subscription = _subscription;
        getIt<AnalyticsService>().logEvent(
          AnalyticsEvents.subscriptionCancel,
          parameters: {
            if (plan != null) ...PaymentEventProperties.fromPlan(plan: plan),
            if (subscription?.paidCount != null)
              AnalyticsProperties.subscriptionCount: subscription!.paidCount,
            AnalyticsProperties.source: AnalyticsValues.sourcePaymentSettings,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Autopay cancelled. You keep access until the end of your paid period.',
            ),
          ),
        );
        await _reload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payment settings')),
      body: SafeArea(
        child: BlocBuilder<EntitlementCubit, AsyncValue<Entitlement>>(
          builder: (context, state) {
            return state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorStateView.fromFailure(
                title: 'Could not load payment settings',
                failure: error is Failure
                    ? error
                    : UnknownFailure(error.toString()),
                onRetry: _reload,
              ),
              data: (entitlement) {
                if (_loadingSubscription) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_subscriptionError != null) {
                  return ErrorStateView.fromFailure(
                    title: 'Could not load subscription',
                    failure: _subscriptionError!,
                    onRetry: _reload,
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        children: [
                          PlanDetailsCard(
                            entitlement: entitlement,
                            subscription: _subscription,
                            plan: _plan,
                          ),
                        ],
                      ),
                    ),
                    if (_canRenew(entitlement))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.xl,
                        ),
                        child: RenewSubscriptionButton(
                          onPressed: _openRenewalPaywall,
                        ),
                      ),
                    if (_canCancel(entitlement))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.xl,
                        ),
                        child: CancelSubscriptionButton(
                          isLoading: _cancelling,
                          onPressed: _confirmCancel,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
