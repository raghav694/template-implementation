import 'dart:async';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/constants/paywall_sources.dart';
import 'package:app_template/core/deeplink/offer_type.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/features/paywall/domain/entities/paywall_plan_selection.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_checkout_cubit.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_plan_cubit.dart';
import 'package:app_template/features/paywall/presentation/widgets/paywall_content.dart';
import 'package:app_template/features/paywall/presentation/widgets/paywall_header.dart';
import 'package:app_template/features/paywall/presentation/widgets/paywall_loading.dart';
import 'package:app_template/shared/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PaywallView extends StatefulWidget {
  const PaywallView({this.deeplinkPlanId, this.offerType, this.source, super.key});

  final String? deeplinkPlanId;
  final OfferType? offerType;
  final String? source;

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> with WidgetsBindingObserver {
  String? _requestedId;
  DateTime? _openedAt;
  var _loggedShown = false;
  bool? _wasPushed;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wasPushed ??= GoRouter.of(context).canPop();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PaywallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deeplinkPlanId != widget.deeplinkPlanId ||
        oldWidget.source != widget.source) {
      _requestedId = null;
      _loadIfNeeded();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!context.read<PaywallCheckoutCubit>().didSucceed) {
      context.read<PaywallCheckoutCubit>().onReturnedFromCheckout();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    getIt<PaywallPlanCubit>().clearForcedPlanId();
    final checkout = getIt<PaywallCheckoutCubit>();
    if (!_loggedShown || checkout.didSucceed || !(_wasPushed ?? false)) {
      super.dispose();
      return;
    }
    final elapsed = _openedAt == null
        ? 0
        : DateTime.now().difference(_openedAt!).inSeconds;
    unawaited(
      getIt<AnalyticsService>().logEvent(
        AnalyticsEvents.paywallDismissed,
        parameters: {
          AnalyticsProperties.triggerSource: (_wasPushed ?? false)
              ? AnalyticsValues.profileUpgrade
              : AnalyticsValues.appRedirect,
          AnalyticsProperties.timeOnPaywallSeconds: elapsed,
        },
      ),
    );
    super.dispose();
  }

  bool get _isDismissible {
    if (PaywallSources.isInit(widget.source)) return false;
    if (PaywallSources.isRenewal(widget.source) && !(_wasPushed ?? false)) {
      return false;
    }
    return true;
  }

  void _loadIfNeeded() {
    final id = widget.deeplinkPlanId?.trim();
    final skipTrial = PaywallSources.isRenewal(widget.source);
    final key = '${id ?? ''}|${widget.source ?? ''}';
    if (_requestedId == key) return;
    _requestedId = key;
    context.read<PaywallPlanCubit>().load(
      deeplinkPlanId: id,
      skipTrial: skipTrial,
    );
  }

  void _logShown(String? planId) {
    if (_loggedShown) return;
    _loggedShown = true;
    unawaited(
      getIt<AnalyticsService>().logEvent(
        AnalyticsEvents.paywallShown,
        parameters: {
          AnalyticsProperties.triggerSource: (_wasPushed ?? false)
              ? AnalyticsValues.profileUpgrade
              : AnalyticsValues.appRedirect,
          if (planId != null && planId.isNotEmpty)
            AnalyticsProperties.planId: planId,
          if (widget.source != null) AnalyticsProperties.source: widget.source,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkingOut = context
        .watch<PaywallCheckoutCubit>()
        .state
        .isCheckingOut;
    final dismissible = _isDismissible;
    return PopScope(
      canPop: dismissible && !checkingOut,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: Column(
            children: [
              PaywallHeader(showClose: dismissible),
              Expanded(
                child:
                    BlocBuilder<
                      PaywallPlanCubit,
                      AsyncValue<PaywallPlanSelection>
                    >(
                      builder: (context, state) {
                        return state.when(
                          loading: () {
                            _logShown(widget.deeplinkPlanId);
                            return const PaywallLoading();
                          },
                          error: (error, _) {
                            _logShown(widget.deeplinkPlanId);
                            return ErrorStateView.fromFailure(
                              title: 'Could not load plans',
                              failure: error is Failure
                                  ? error
                                  : UnknownFailure(error.toString()),
                              onRetry: () => context.read<PaywallPlanCubit>().load(
                                deeplinkPlanId: widget.deeplinkPlanId,
                                skipTrial: PaywallSources.isRenewal(widget.source),
                              ),
                            );
                          },
                          data: (selection) {
                            _logShown(selection.plan.id);
                            return PaywallContent(
                              selection: selection,
                              offerType: widget.offerType,
                              source: widget.source,
                            );
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
