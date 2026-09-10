import 'dart:async';

import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/paywall/presentation/bloc/paywall_checkout_cubit.dart';
import 'package:app_template/features/paywall/presentation/widgets/qr_sheet_view.dart';
import 'package:app_template/features/paywall/presentation/widgets/upi_app_selector.dart';
import 'package:app_template/features/paywall/presentation/widgets/upi_qr_code.dart';
import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';
import 'package:flutter/material.dart';

typedef PaywallPayButtonBuilder =
    Widget Function(VoidCallback? onPressed, bool isPaying);

typedef PaywallPayStartedCallback =
    Future<void> Function({
      required bool useQr,
      required List<String> paymentApps,
      String? selectedPackageName,
    });

typedef PaywallPayErrorCallback =
    Future<void> Function(Object error, {bool? useQr});

/// Host-owned checkout UI. Capslock SDK supplies initiate, UPI launch, QR
/// payload, and [CheckoutClient.watchCheckoutStatus].
///
/// QR checkout opens a single non-dismissible bottom sheet on the same tap
/// that starts payment. There is no Reset — Cancel and try again.
class PaywallCheckout extends StatefulWidget {
  const PaywallCheckout({
    super.key,
    required this.client,
    required this.tenantId,
    required this.planId,
    required this.customer,
    required this.button,
    this.qrSize = 200,
    this.qrTtl = const Duration(minutes: 5),
    this.onInitiated,
    this.onInAppCheckout,
    this.onUpiAppsLoaded,
    this.onPayStarted,
    this.onQrExpired,
    this.onQrReset,
    this.onSuccess,
    this.onError,
  });

  final CheckoutClient client;
  final String tenantId;
  final String planId;
  final InitiatePaymentCustomer customer;
  final PaywallPayButtonBuilder button;
  final double qrSize;
  final Duration qrTtl;
  final ValueChanged<InitiatePaymentResponse>? onInitiated;
  final VoidCallback? onInAppCheckout;
  final ValueChanged<List<UpiAppInfo>>? onUpiAppsLoaded;
  final PaywallPayStartedCallback? onPayStarted;
  final VoidCallback? onQrExpired;
  final VoidCallback? onQrReset;
  final ValueChanged<InitiatePaymentResponse>? onSuccess;
  final PaywallPayErrorCallback? onError;

  @override
  State<PaywallCheckout> createState() => _PaywallCheckoutState();
}

class _PaywallCheckoutState extends State<PaywallCheckout>
    with WidgetsBindingObserver {
  List<UpiAppInfo> _upiApps = const [];
  UpiAppInfo? _selectedUpiApp;
  var _loadingApps = true;
  var _paying = false;
  var _payGeneration = 0;
  var _qrSheetOpen = false;
  final _qrView = ValueNotifier<QrSheetView?>(null);
  Timer? _qrTtlTimer;
  InitiatePaymentResponse? _pending;
  StreamSubscription<CheckoutStatusEvent>? _statusWatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUpiApps();
  }

  @override
  void dispose() {
    _qrTtlTimer?.cancel();
    _statusWatch?.cancel();
    _qrView.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _pending == null) return;
    if (!_qrSheetOpen && _paying && mounted) {
      setState(() => _paying = false);
    }
  }

  List<String> get _paymentAppNames =>
      _upiApps.map((app) => app.appName).toList(growable: false);

  Future<void> _loadUpiApps() async {
    final result = await UpiService.getAvailablePaymentsAppsInfo();
    if (!mounted) return;
    setState(() {
      _upiApps = result.apps;
      _selectedUpiApp = result.apps.isEmpty ? null : result.apps.first;
      _loadingApps = false;
    });
    widget.onUpiAppsLoaded?.call(result.apps);
  }

  Future<void> _onPay() async {
    final app = _selectedUpiApp;
    final useQr = app == null;
    final selectionError = PaywallCheckoutCubit.upiSelectionError(
      useQr: useQr,
      hasUpiApps: _upiApps.isNotEmpty,
    );
    if (selectionError != null) {
      await widget.onError?.call(selectionError, useQr: false);
      return;
    }

    final generation = ++_payGeneration;
    _statusWatch?.cancel();
    _statusWatch = null;
    _pending = null;
    setState(() {
      _paying = true;
      if (!useQr) {
        _stopQrTtl();
        _qrView.value = null;
      }
    });
    try {
      await widget.onPayStarted?.call(
        useQr: useQr,
        paymentApps: _paymentAppNames,
        selectedPackageName: useQr ? null : app?.packageName,
      );
      if (!mounted || generation != _payGeneration) return;
      final response = await widget.client.initiatePayment(
        InitiatePaymentRequest(
          tenantId: widget.tenantId,
          planId: widget.planId,
          customer: widget.customer,
          deviceOs: 'ANDROID',
        ),
      );
      if (!mounted || generation != _payGeneration) return;
      final launch = PaywallCheckoutCubit.resolveLaunch(
        response: response,
        useQr: useQr,
        packageName: useQr ? null : app?.packageName,
      );
      _pending = launch.response;
      if (launch.useQr) {
        if (!mounted || generation != _payGeneration) return;
        setState(() => _paying = false);
        _startQrTtl(launch.qrPayload!);
        widget.onInAppCheckout?.call();
        _startStatusWatch(launch.response, inAppQr: true);
        await _presentQrSheet();
        return;
      }
      await UpiService.openUpiApp(
        upiIntentUrl: launch.intentUrl!,
        targetPackage: launch.packageName!,
      );
      if (!mounted || generation != _payGeneration) return;
      setState(() => _paying = false);
      _startStatusWatch(launch.response, inAppQr: false);
    } catch (error) {
      if (generation != _payGeneration) return;
      _pending = null;
      if (!mounted) return;
      setState(() => _paying = false);
      await widget.onError?.call(error, useQr: useQr);
    }
  }

  Future<void> _presentQrSheet() async {
    if (!mounted || _qrSheetOpen) return;
    _qrSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (sheetContext) {
        return PopScope(
          canPop: false,
          child: ValueListenableBuilder<QrSheetView?>(
            valueListenable: _qrView,
            builder: (context, view, _) {
              if (view == null) {
                return const SizedBox.shrink();
              }
              return SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: UpiQrCode(
                    data: view.data,
                    size: widget.qrSize,
                    expired: view.expired,
                    remaining: view.remaining,
                    onCancel: () {
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    _qrSheetOpen = false;
    if (!mounted) return;
    if (_qrView.value != null) {
      _resetQr(notify: true);
    }
  }

  void _popQrSheetIfOpen() {
    if (!_qrSheetOpen || !mounted) return;
    final navigator = Navigator.of(context, rootNavigator: false);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _resetQr({bool notify = true}) {
    _payGeneration++;
    _statusWatch?.cancel();
    _statusWatch = null;
    _pending = null;
    _stopQrTtl();
    _qrView.value = null;
    if (mounted) {
      setState(() => _paying = false);
    }
    if (notify) {
      widget.onQrReset?.call();
    }
  }

  void _startQrTtl(String payload) {
    _qrTtlTimer?.cancel();
    final expiresAt = DateTime.now().add(widget.qrTtl);
    _qrView.value = QrSheetView(
      data: payload,
      expired: false,
      remaining: widget.qrTtl,
    );
    _qrTtlTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = expiresAt.difference(DateTime.now());
      if (left <= Duration.zero) {
        _markQrExpired();
        return;
      }
      final current = _qrView.value;
      if (current == null) return;
      _qrView.value = QrSheetView(
        data: current.data,
        expired: false,
        remaining: left,
      );
    });
  }

  void _stopQrTtl() {
    _qrTtlTimer?.cancel();
    _qrTtlTimer = null;
  }

  void _markQrExpired() {
    _qrTtlTimer?.cancel();
    _statusWatch?.cancel();
    _statusWatch = null;
    final current = _qrView.value;
    if (current != null) {
      _qrView.value = QrSheetView(
        data: current.data,
        expired: true,
        remaining: Duration.zero,
      );
    }
    if (mounted) {
      setState(() => _paying = false);
    }
    widget.onQrExpired?.call();
  }

  void _startStatusWatch(
    InitiatePaymentResponse checkout, {
    required bool inAppQr,
  }) {
    _statusWatch?.cancel();
    _statusWatch = null;
    widget.onInitiated?.call(checkout);
    if (widget.onInitiated != null && !inAppQr) {
      return;
    }

    _statusWatch = widget.client
        .watchCheckoutStatus(
          WatchCheckoutStatusRequest(
            tenantId: widget.tenantId,
            checkout: checkout,
          ),
        )
        .listen(
          _onWatchEvent,
          onError: (Object error) {
            _clearPending(popQr: true);
            unawaited(widget.onError?.call(error, useQr: true));
          },
        );
  }

  void _onWatchEvent(CheckoutStatusEvent event) {
    final outcome = PaywallCheckoutCubit.watchOutcome(
      event,
      hasActiveQr: _qrView.value != null,
    );
    if (outcome.isIgnore) return;
    if (outcome.isQrExpired) {
      _markQrExpired();
      return;
    }
    _clearPending(popQr: true);
    if (outcome.isSuccess) {
      widget.onSuccess?.call(outcome.checkout!);
      return;
    }
    unawaited(widget.onError?.call(outcome.error!, useQr: outcome.useQr));
  }

  void _clearPending({required bool popQr}) {
    _pending = null;
    _statusWatch?.cancel();
    _statusWatch = null;
    _stopQrTtl();
    if (popQr) {
      _qrView.value = null;
      _popQrSheetIfOpen();
    }
    if (!mounted) return;
    setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    final canPay = !_paying && (_selectedUpiApp != null || _upiApps.isEmpty);
    if (_loadingApps) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UpiAppSelector(
          upiApps: _upiApps,
          selectedApp: _selectedUpiApp,
          onAppSelected: (app) => setState(() => _selectedUpiApp = app),
        ),
        if (_upiApps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'No UPI apps found on this device. Pay to show a QR code.',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        widget.button(canPay ? _onPay : null, _paying),
      ],
    );
  }
}
