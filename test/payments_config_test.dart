import 'package:app_template/core/payments/payments_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps Capslock ACTIVE to entitled active', () {
    expect(PaymentsConfig.toAppSubscriptionStatus('ACTIVE'), 'active');
  });

  test(
    'maps Capslock PENDING to initiated so it is not treated as entitled',
    () {
      expect(PaymentsConfig.toAppSubscriptionStatus('PENDING'), 'initiated');
    },
  );

  test('maps canceled spellings onto canceled', () {
    expect(PaymentsConfig.toAppSubscriptionStatus('CANCELED'), 'canceled');
    expect(PaymentsConfig.toAppSubscriptionStatus('CANCELLED'), 'canceled');
    expect(PaymentsConfig.isCanceled('canceled'), isTrue);
    expect(PaymentsConfig.isCanceled('CANCELLED'), isTrue);
    expect(PaymentsConfig.isCanceled('active'), isFalse);
  });
}
