import 'package:app_template/features/analytics/checkout_ids.dart';
import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

InitiatePaymentResponse _checkout({
  String paymentId = '',
  String gatewayOrderId = '',
  String gatewaySubscriptionId = '',
  String subscriptionId = '',
}) {
  return InitiatePaymentResponse(
    paymentId: paymentId,
    subscriptionId: subscriptionId,
    customerId: 'cus',
    planId: 'monthly',
    provider: 'CASHFREE',
    type: 'RECURRING',
    status: 'PENDING',
    gatewaySubscriptionId: gatewaySubscriptionId,
    gatewayOrderId: gatewayOrderId,
    checkoutSessionId: 'cs',
    checkoutLinks: const CheckoutLinks(
      android: {},
      ios: {},
      url: '',
      qrData: '',
    ),
    nextBillingAt: '',
  );
}

void main() {
  test('prefers initiate paymentId then gateway then subscription', () {
    expect(
      analyticsPaymentId(
        _checkout(
          paymentId: 'pay_1',
          gatewayOrderId: 'ord_1',
          subscriptionId: 'sub_1',
        ),
      ),
      'pay_1',
    );
    expect(
      analyticsPaymentId(
        _checkout(gatewayOrderId: 'ord_1', subscriptionId: 'sub_1'),
      ),
      'ord_1',
    );
    expect(
      analyticsPaymentId(
        _checkout(gatewaySubscriptionId: 'gw_sub', subscriptionId: 'sub_1'),
      ),
      'gw_sub',
    );
    expect(analyticsPaymentId(_checkout(subscriptionId: 'sub_1')), 'sub_1');
    expect(analyticsPaymentId(_checkout()), '');
  });
}
