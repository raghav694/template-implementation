import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:app_template/features/paywall/domain/services/payment_event_properties.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const plan = Plan(
    id: 'monthly',
    label: 'Monthly',
    priceAmount: 149,
    billingCycle: 'month',
    trialDays: 7,
    trialAmount: 1,
    videoUrl: 'https://cdn.example/hero.mp4',
  );

  test('fromPlan maps Shanti-compatible plan keys', () {
    final props = PaymentEventProperties.fromPlan(plan: plan);
    expect(props[AnalyticsProperties.planId], 'monthly');
    expect(props[AnalyticsProperties.trialAmount], 1);
    expect(props[AnalyticsProperties.subscriptionAmount], 149);
    expect(props[AnalyticsProperties.mediaURL], 'https://cdn.example/hero.mp4');
    expect(props[AnalyticsProperties.planFrequency], 'month');
  });

  test('fromPlan zeroes trialAmount on renewal', () {
    final props = PaymentEventProperties.fromPlan(plan: plan, skipTrial: true);
    expect(props[AnalyticsProperties.trialAmount], 0);
    expect(props[AnalyticsProperties.subscriptionAmount], 149);
  });

  test('upi omits empty selectedPackageName', () {
    final qr = PaymentEventProperties.upi(
      paymentApps: const ['GPay'],
      selectedPackageName: null,
      paymentMethod: AnalyticsValues.paymentMethodQrCode,
    );
    expect(qr[AnalyticsProperties.paymentApps], ['GPay']);
    expect(qr[AnalyticsProperties.paymentMethod], 'qrcode');
    expect(qr.containsKey(AnalyticsProperties.selectedPackageName), isFalse);

    final link = PaymentEventProperties.upi(
      paymentApps: const ['GPay'],
      selectedPackageName: 'com.google.android.apps.nbu.paisa.user',
      paymentMethod: AnalyticsValues.paymentMethodLink,
    );
    expect(
      link[AnalyticsProperties.selectedPackageName],
      'com.google.android.apps.nbu.paisa.user',
    );
    expect(link[AnalyticsProperties.paymentMethod], 'link');
  });

  test('rechargeAmount is only set for one-time plans', () {
    expect(
      PaymentEventProperties.rechargeAmountInr(plan: plan, chargedAmountInr: 1),
      isNull,
    );
    const oneTime = Plan(
      id: 'lifetime',
      label: 'Lifetime',
      priceAmount: 2999,
      billingCycle: 'once',
      category: PlanCategory.oneTime,
    );
    expect(
      PaymentEventProperties.rechargeAmountInr(
        plan: oneTime,
        chargedAmountInr: 2999,
      ),
      2999,
    );
    expect(
      PaymentEventProperties.rechargeType(plan),
      AnalyticsValues.rechargeTypeSubs,
    );
    expect(
      PaymentEventProperties.rechargeType(oneTime),
      AnalyticsValues.rechargeTypeNormal,
    );
  });
}
