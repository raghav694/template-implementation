import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';

/// QR payload or UPI intent URL resolved from an initiate response.
class CheckoutLaunch {
  const CheckoutLaunch.qr({required this.response, required this.qrPayload})
    : useQr = true,
      intentUrl = null,
      packageName = null;

  const CheckoutLaunch.intent({
    required this.response,
    required this.intentUrl,
    required this.packageName,
  }) : useQr = false,
       qrPayload = null;

  final InitiatePaymentResponse response;
  final bool useQr;
  final String? qrPayload;
  final String? intentUrl;
  final String? packageName;
}
