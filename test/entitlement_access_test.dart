import 'package:app_template/features/auth/data/models/user_model.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('User.isPremium is false for free and empty entitlement', () {
    expect(const User(id: '1', phone: '1').isPremium, isFalse);
    expect(
      const User(id: '1', phone: '1', entitlement: 'free').isPremium,
      isFalse,
    );
  });

  test('User.isPremium is true for any non-free entitlement', () {
    expect(
      const User(id: '1', phone: '1', entitlement: 'premium').isPremium,
      isTrue,
    );
    expect(
      const User(id: '1', phone: '1', entitlement: 'pro').isPremium,
      isTrue,
    );
  });

  test('User.isPremium is false when validity end is in the past', () {
    expect(
      User(
        id: '1',
        phone: '1',
        entitlement: 'premium',
        expiresAt: DateTime(2020, 1, 1),
      ).isPremium,
      isFalse,
    );
  });

  test('User.isPremium is true when validity end is in the future', () {
    expect(
      User(
        id: '1',
        phone: '1',
        entitlement: 'premium',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ).isPremium,
      isTrue,
    );
  });

  test('UserModel parses has_purchased and validity_end_at from profile JSON', () {
    final model = UserModel.fromJson({
      'id': 'u1',
      'phone_number': '+919000000000',
      'entitlement': 'premium',
      'has_purchased': true,
      'validity_end_at': '2020-01-01T00:00:00Z',
    });
    final user = model.toEntity();
    expect(user.hasPurchased, isTrue);
    expect(user.expiresAt, isNotNull);
    expect(user.isPremium, isFalse);
    expect(model.toStoreJson()['has_purchased'], isTrue);
    expect(model.toStoreJson()['validity_end_at'], isNotNull);
  });

  test('renewal charges the full plan price, not the trial', () {
    const plan = Plan(
      id: 'monthly',
      label: 'Monthly',
      priceAmount: 149,
      billingCycle: 'month',
      trialDays: 3,
      trialAmount: 2,
    );
    expect(plan.chargeAmount, 2);
    expect(plan.chargeAmountFor(skipTrial: true), 149);
    expect(plan.showTrialPrice(skipTrial: true), isFalse);
    expect(plan.showTrialPrice(skipTrial: false), isTrue);
    expect(plan.withoutTrial().hasTrial, isFalse);
    expect(plan.withoutTrial().priceAmount, 149);
  });

  test('one-time plans are not recurring', () {
    const plan = Plan(
      id: 'lifetime',
      label: 'Lifetime',
      priceAmount: 999,
      billingCycle: 'lifetime',
      category: PlanCategory.oneTime,
    );
    expect(plan.isRecurring, isFalse);
    expect(plan.billingPeriodLabel, 'once');
  });

  test('Capslock active status with past validity end is not entitled', () {
    final subscription = Subscription(
      userId: 'u1',
      status: 'active',
      plan: 'monthly',
      currentEnd: DateTime(2020, 1, 1),
    );
    expect(subscription.isActive, isFalse);
  });

  test('cancelled Autopay stays entitled until validity end', () {
    final subscription = Subscription(
      userId: 'u1',
      status: 'canceled',
      plan: 'monthly',
      currentEnd: DateTime.now().add(const Duration(days: 10)),
    );
    expect(subscription.isActive, isTrue);
  });

  test('cancelled Autopay without a validity end is not entitled', () {
    const subscription = Subscription(
      userId: 'u1',
      status: 'canceled',
      plan: 'monthly',
    );
    expect(subscription.isActive, isFalse);
  });
}
