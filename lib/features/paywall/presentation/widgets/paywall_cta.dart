import 'dart:async';
import 'dart:io';

import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/constants/paywall_sources.dart';
import 'package:app_template/core/constants/route_paths.dart';
import 'package:app_template/core/deeplink/offer_type.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/presentation/bloc/entitlement_cubit.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_checkout_cubit.dart';
import 'package:app_template/features/paywall/presentation/widgets/payment_status_bottom_sheet.dart';
import 'package:app_template/features/paywall/presentation/widgets/paywall_checkout.dart';
import 'package:app_template/features/paywall/presentation/widgets/paywall_checkout_hint.dart';
import 'package:capslock_payments_sdk/capslock_payments_sdk.dart' hide Plan;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PaywallCta extends StatefulWidget {
  const PaywallCta({
    required this.plan,
    this.source,
    this.offerType,
    super.key,
  });

  final Plan plan;
  final String? source;
  final OfferType? offerType;

  @override
  State<PaywallCta> createState() => _PaywallCtaState();
}

class _PaywallCtaState extends State<PaywallCta> {
  StreamSubscription<CheckoutStatusEvent>? _statusWatch;
  late final ValueNotifier<PaymentStatusView> _checkoutSheetView;
  var _inAppQr = false;
  var _widgetGeneration = 0;
  var _checkoutAttempt = 0;
  var _checkoutSheetOpen = false;
  var _showingOutcome = false;
  var _succeeded = false;
  var _scheduledHintLog = false;

  @override
  void initState() {
    super.initState();
    _checkoutSheetView = ValueNotifier(
      const PaymentStatusView(phase: PaymentStatusPhase.processing),
    );
  }

  @override
  void dispose() {
    unawaited(_statusWatch?.cancel());
    _checkoutSheetView.dispose();
    super.dispose();
  }

  String get _footnote {
    final plan = widget.plan;
    final skipTrial = PaywallSources.isRenewal(widget.source);
    if (plan.showTrialPrice(skipTrial: skipTrial)) {
      return 'then ${plan.currencySymbol}${plan.priceAmount}/${plan.billingPeriodLabel} · Cancel anytime';
    }
    return switch (plan.category) {
      PlanCategory.recurring => 'UPI Autopay · Cancel anytime',
      PlanCategory.oneTime => 'One-time payment',
    };
  }

  String get _ctaLabel {
    if (PaywallSources.isRenewal(widget.source)) return 'Renew Now';
    return 'Unlock Now';
  }

  void _abandonCheckoutWatch() {
    _checkoutAttempt++;
    unawaited(_statusWatch?.cancel());
    _statusWatch = null;
  }

  Future<void> _onPayStarted({
    required bool useQr,
    required List<String> paymentApps,
    String? selectedPackageName,
  }) {
    _abandonCheckoutWatch();
    final user = context.read<AuthCubit>().state.valueOrNull;
    final isPremium =
        context.read<EntitlementCubit>().state.valueOrNull?.isPremium == true;
    return context.read<PaywallCheckoutCubit>().onPayStarted(
      widget.plan,
      userId: user?.id ?? '',
      isPremium: isPremium,
      useQr: useQr,
      paymentApps: paymentApps,
      selectedPackageName: selectedPackageName,
      source: widget.source,
      offerType: widget.offerType?.apiValue,
    );
  }

  void _onUpiAppsLoaded(List<UpiAppInfo> apps) {
    unawaited(
      context.read<PaywallCheckoutCubit>().onPaymentScreenReady(
        widget.plan,
        paymentApps: apps.map((app) => app.appName).toList(growable: false),
        source: widget.source,
      ),
    );
  }

  void _logPaymentScreenWithoutUpi() {
    if (_scheduledHintLog) return;
    _scheduledHintLog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<PaywallCheckoutCubit>().onPaymentScreenReady(
          widget.plan,
          paymentApps: const [],
          source: widget.source,
        ),
      );
    });
  }

  void _onInAppQrShown() {
    _inAppQr = true;
    context.read<PaywallCheckoutCubit>().onReturnedFromCheckout();
  }

  void _onQrReset() {
    _inAppQr = false;
    _abandonCheckoutWatch();
    context.read<PaywallCheckoutCubit>().onReturnedFromCheckout();
  }

  void _onInitiated(InitiatePaymentResponse checkout) {
    unawaited(context.read<PaywallCheckoutCubit>().attachCheckout(checkout));
    if (_inAppQr) return;
    _checkoutSheetView.value = const PaymentStatusView(
      phase: PaymentStatusPhase.processing,
    );
    _checkoutSheetOpen = true;
    _watchCheckoutStatus(checkout);
    unawaited(_presentUpiResultSheet());
  }

  void _watchCheckoutStatus(InitiatePaymentResponse checkout) {
    final attempt = _checkoutAttempt;
    unawaited(_statusWatch?.cancel());
    _statusWatch = getIt<CheckoutClient>()
        .watchCheckoutStatus(
          WatchCheckoutStatusRequest(
            tenantId: AppConfig.paymentsTenantId,
            checkout: checkout,
          ),
        )
        .listen(
          (event) {
            if (attempt != _checkoutAttempt) return;
            final outcome = PaywallCheckoutCubit.watchOutcome(
              event,
              hasActiveQr: _inAppQr,
            );
            if (outcome.isIgnore || outcome.isQrExpired) return;
            unawaited(_statusWatch?.cancel());
            _statusWatch = null;
            if (outcome.isSuccess) {
              unawaited(_onSuccess(outcome.checkout!));
              return;
            }
            unawaited(_onError(outcome.error!, useQr: outcome.useQr));
          },
          onError: (Object error) {
            if (attempt != _checkoutAttempt) return;
            unawaited(_onError(error, useQr: false));
          },
        );
  }

  Future<void> _presentUpiResultSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentStatusBottomSheet(
        view: _checkoutSheetView,
        onCancel: _cancelUpiCheckout,
      ),
    );
    _checkoutSheetOpen = false;
    _checkoutSheetView.value = const PaymentStatusView(
      phase: PaymentStatusPhase.processing,
    );
    if (!mounted) return;
    if (_succeeded) {
      unawaited(_enterAppAfterSuccess());
      return;
    }
    setState(() => _widgetGeneration++);
  }

  void _cancelUpiCheckout() {
    if (_showingOutcome || _succeeded) return;
    _abandonCheckoutWatch();
    unawaited(
      _onError(
        const PaymentFailure('Payment was cancelled. Please try again.'),
      ),
    );
  }

  Future<void> _onSuccess(InitiatePaymentResponse response) async {
    if (_showingOutcome || _succeeded) return;
    if (_checkoutSheetView.value.phase == PaymentStatusPhase.failed) return;
    _showingOutcome = true;
    try {
      final user = context.read<AuthCubit>().state.valueOrNull;
      await context.read<PaywallCheckoutCubit>().onPaySuccess(
        response,
        userId: user?.id ?? '',
        plan: widget.plan,
      );
      if (!mounted) return;
      _succeeded = true;
      if (_checkoutSheetOpen) {
        _checkoutSheetView.value = const PaymentStatusView(
          phase: PaymentStatusPhase.success,
        );
        return;
      }
      await _showResultSheet(
        const PaymentStatusView(phase: PaymentStatusPhase.success),
      );
      if (!mounted) return;
      await _enterAppAfterSuccess();
    } finally {
      _showingOutcome = false;
    }
  }

  Future<void> _onError(Object error, {bool? useQr}) async {
    if (_showingOutcome || _succeeded) return;
    if (_checkoutSheetView.value.phase == PaymentStatusPhase.success) return;
    _showingOutcome = true;
    try {
      await context.read<PaywallCheckoutCubit>().onPayError(
        error,
        useQr: useQr,
      );
      if (!mounted) return;
      final view = PaymentStatusView(
        phase: PaymentStatusPhase.failed,
        errorMessage:
            context.read<PaywallCheckoutCubit>().state.errorMessage ??
            'Payment could not be completed. Please try again.',
      );
      if (_checkoutSheetOpen) {
        _checkoutSheetView.value = view;
        return;
      }
      await _showResultSheet(view);
      if (!mounted) return;
      setState(() => _widgetGeneration++);
    } finally {
      _showingOutcome = false;
    }
  }

  Future<void> _enterAppAfterSuccess() async {
    final auth = context.read<AuthCubit>();
    final userId = auth.state.valueOrNull?.id ?? '';
    await context.read<PaywallCheckoutCubit>().enterAppAfterSuccessfulPurchase(
      userId,
    );
    await auth.refreshProfile();
    if (!mounted) return;
    final user = auth.state.valueOrNull;
    if (user != null) {
      await context.read<EntitlementCubit>().refreshFor(
        userId: user.id,
        isPremium: user.isPremium,
        hasPurchased: user.hasPurchased,
        expiresAt: user.expiresAt,
      );
    }
    if (!mounted) return;
    context.go(RoutePaths.home);
  }

  Future<void> _showResultSheet(PaymentStatusView view) {
    final notifier = ValueNotifier(view);
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentStatusBottomSheet(view: notifier),
    ).whenComplete(notifier.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _checkoutBody(context),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _footnote,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkoutBody(BuildContext context) {
    if (!AppConfig.hasPaymentsConfig) {
      _logPaymentScreenWithoutUpi();
      return PaywallCheckoutHint(
        _ctaLabel,
        'Set PAYMENTS_BASE_URL and PAYMENTS_TENANT_ID to enable checkout.',
      );
    }
    if (kIsWeb || !Platform.isAndroid) {
      _logPaymentScreenWithoutUpi();
      return const PaywallCheckoutHint(
        'Continue',
        'UPI checkout in this template is Android-only.',
      );
    }

    final user = context.watch<AuthCubit>().state.valueOrNull;
    final customer = user == null
        ? null
        : PaywallCheckoutCubit.customerFor(
            userId: user.id,
            phone: user.phone,
            displayName: user.displayName,
            email: user.email,
          );
    if (customer == null) {
      _logPaymentScreenWithoutUpi();
      return PaywallCheckoutHint(
        _ctaLabel,
        user == null
            ? 'Sign in to continue with payment.'
            : 'A phone number is required for UPI Autopay.',
      );
    }

    return PaywallCheckout(
      key: ValueKey(_widgetGeneration),
      client: getIt<CheckoutClient>(),
      tenantId: AppConfig.paymentsTenantId,
      planId: widget.plan.id,
      customer: customer,
      qrSize: 168,
      onInitiated: _onInitiated,
      onInAppCheckout: _onInAppQrShown,
      onUpiAppsLoaded: _onUpiAppsLoaded,
      onPayStarted: _onPayStarted,
      onQrExpired: _abandonCheckoutWatch,
      onQrReset: _onQrReset,
      onSuccess: (checkout) => unawaited(_onSuccess(checkout)),
      onError: (error, {bool? useQr}) => _onError(error, useQr: useQr),
      button: (onPressed, isPaying) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: isPaying ? null : onPressed,
          child: Text(isPaying ? 'Waiting for UPI…' : _ctaLabel),
        ),
      ),
    );
  }
}
