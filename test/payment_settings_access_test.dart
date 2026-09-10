import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:app_template/features/paywall/domain/services/payment_settings_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const recurring = Plan(
    id: 'monthly',
    label: 'Monthly',
    priceAmount: 149,
    billingCycle: 'month',
  );
  const lifetime = Plan(
    id: 'lifetime',
    label: 'Lifetime',
    priceAmount: 999,
    billingCycle: 'lifetime',
    category: PlanCategory.oneTime,
  );
  final active = Subscription(
    userId: 'u1',
    status: 'active',
    plan: 'monthly',
    currentEnd: DateTime.now().add(const Duration(days: 20)),
  );
  final canceled = Subscription(
    userId: 'u1',
    status: 'canceled',
    plan: 'monthly',
    currentEnd: DateTime.now().add(const Duration(days: 20)),
  );

  test('active premium recurring can cancel and cannot renew', () {
    expect(
      PaymentSettingsAccess.canCancel(
        isPremium: true,
        isOneTime: PaymentSettingsAccess.isOneTimePlan(recurring),
        subscription: active,
      ),
      isTrue,
    );
    expect(
      PaymentSettingsAccess.canRenew(
        isPremium: true,
        isOneTime: false,
        subscription: active,
      ),
      isFalse,
    );
  });

  test('cancelled-but-premium recurring can renew and cannot cancel', () {
    expect(
      PaymentSettingsAccess.canCancel(
        isPremium: true,
        isOneTime: false,
        subscription: canceled,
      ),
      isFalse,
    );
    expect(
      PaymentSettingsAccess.canRenew(
        isPremium: true,
        isOneTime: false,
        subscription: canceled,
      ),
      isTrue,
    );
  });

  test('expired / free users cannot renew from settings', () {
    expect(
      PaymentSettingsAccess.canRenew(
        isPremium: false,
        isOneTime: false,
        subscription: canceled,
      ),
      isFalse,
    );
  });

  test('one-time plans have no cancel or renew', () {
    expect(PaymentSettingsAccess.isOneTimePlan(lifetime), isTrue);
    expect(
      PaymentSettingsAccess.canCancel(
        isPremium: true,
        isOneTime: true,
        subscription: active,
      ),
      isFalse,
    );
    expect(
      PaymentSettingsAccess.canRenew(
        isPremium: true,
        isOneTime: true,
        subscription: canceled,
      ),
      isFalse,
    );
  });
}
