import 'package:app_template/features/paywall/data/datasources/plan_remote_datasource_impl.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:capslock_payments_sdk/capslock_payments_sdk.dart' as payments;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a monthly Capslock plan to rupees and Autopay', () {
    final plan = toDomainPlan(
      const payments.Plan(
        id: 'monthly',
        tenantId: 'tenant',
        amountMinor: 14900,
        currency: 'INR',
        interval: 'month',
        type: 'RECURRING',
        status: 'ACTIVE',
      ),
    );

    expect(plan.id, 'monthly');
    expect(plan.label, 'Monthly Premium');
    expect(plan.priceAmount, 149);
    expect(plan.billingCycle, 'month');
    expect(plan.category, PlanCategory.recurring);
    expect(plan.currencyCode, 'INR');
  });

  test('maps a yearly Capslock plan', () {
    final plan = toDomainPlan(
      const payments.Plan(
        id: 'yearly',
        tenantId: 'tenant',
        amountMinor: 99900,
        currency: 'INR',
        interval: 'year',
        type: 'RECURRING',
        status: 'ACTIVE',
      ),
    );

    expect(plan.label, 'Yearly Premium');
    expect(plan.billingCycle, 'year');
    expect(plan.category, PlanCategory.recurring);
  });

  test('maps a one-time Capslock plan', () {
    final plan = toDomainPlan(
      const payments.Plan(
        id: 'lifetime',
        tenantId: 'tenant',
        amountMinor: 299900,
        currency: 'INR',
        interval: 'one_time',
        type: 'ONE_TIME',
        status: 'ACTIVE',
      ),
    );

    expect(plan.label, 'Lifetime');
    expect(plan.billingCycle, 'once');
    expect(plan.category, PlanCategory.oneTime);
  });

  test('maps Capslock trial fields onto the domain plan', () {
    final plan = toDomainPlan(
      const payments.Plan(
        id: 'monthly_trial',
        tenantId: 'tenant',
        amountMinor: 14900,
        currency: 'INR',
        interval: 'month',
        type: 'RECURRING',
        status: 'ACTIVE',
        hasTrial: true,
        trialDuration: 7,
        authorizationAmountMinor: 100,
      ),
    );

    expect(plan.hasTrial, isTrue);
    expect(plan.trialDays, 7);
    expect(plan.trialAmount, 1);
  });

  test('maps Capslock metadata onto label, original price, and video', () {
    final plan = toDomainPlan(
      const payments.Plan(
        id: 'monthly',
        tenantId: 'tenant',
        amountMinor: 14900,
        currency: 'INR',
        interval: 'month',
        type: 'RECURRING',
        status: 'ACTIVE',
        metadata: {
          'label': 'Plus',
          'original_price_inr': '299',
          'video_url': 'https://cdn.example/plan.mp4',
        },
      ),
    );

    expect(plan.label, 'Plus');
    expect(plan.originalPriceAmount, 299);
    expect(plan.discountPercent, 50);
    expect(plan.videoUrl, 'https://cdn.example/plan.mp4');
  });
}
