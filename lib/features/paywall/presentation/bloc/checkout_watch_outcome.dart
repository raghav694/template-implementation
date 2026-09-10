import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';

enum CheckoutWatchKind { ignore, success, qrExpired, failed }

/// How the host should react to a [CheckoutStatusEvent].
class CheckoutWatchOutcome {
  const CheckoutWatchOutcome._(
    this.kind, {
    this.checkout,
    this.error,
    this.useQr = false,
  });

  const CheckoutWatchOutcome.ignore() : this._(CheckoutWatchKind.ignore);

  const CheckoutWatchOutcome.success(InitiatePaymentResponse checkout)
    : this._(CheckoutWatchKind.success, checkout: checkout);

  const CheckoutWatchOutcome.qrExpired() : this._(CheckoutWatchKind.qrExpired);

  const CheckoutWatchOutcome.failed(Object error, {required bool useQr})
    : this._(CheckoutWatchKind.failed, error: error, useQr: useQr);

  final CheckoutWatchKind kind;
  final InitiatePaymentResponse? checkout;
  final Object? error;
  final bool useQr;

  bool get isIgnore => kind == CheckoutWatchKind.ignore;
  bool get isSuccess => kind == CheckoutWatchKind.success;
  bool get isQrExpired => kind == CheckoutWatchKind.qrExpired;
  bool get isFailed => kind == CheckoutWatchKind.failed;
}
