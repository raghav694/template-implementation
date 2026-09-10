import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';

/// Id sent as `paymentId` on `addBalanceSuccess`.
///
/// Recurring Capslock checkout historically omitted `payment_id` (that field
/// is a one-time payment row). Prefer the initiate `payment_id` (Cashfree
/// AUTH / PhonePe setup order), then other checkout identifiers so the event
/// is never missing an id after a successful mandate.
String analyticsPaymentId(InitiatePaymentResponse checkout) {
  for (final value in [
    checkout.paymentId,
    checkout.gatewayOrderId,
    checkout.gatewaySubscriptionId,
    checkout.subscriptionId,
  ]) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}
