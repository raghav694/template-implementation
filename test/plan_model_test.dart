import 'package:app_template/features/paywall/data/models/plan_model.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the REST amount_paise plan payload as Autopay/recurring', () {
    final plan = PlanModel.fromJson({
      'id': 'monthly',
      'name': 'Monthly Premium',
      'amount_paise': 14900,
      'frequency': 'month',
      'trial_period': 3,
      'trial_amount': 100,
    });

    expect(plan.id, 'monthly');
    expect(plan.label, 'Monthly Premium');
    expect(plan.priceAmount, 149);
    expect(plan.billingCycle, 'month');
    expect(plan.category, PlanCategory.recurring);
    expect(plan.hasTrial, isTrue);
    expect(plan.trialAmount, 1);
    expect(plan.billingPeriodLabel, 'month');
  });

  test('maps a one-time plan and original price', () {
    final plan = PlanModel.fromJson({
      'id': 'lifetime',
      'label': 'Lifetime',
      'price_inr': 2999,
      'original_price_inr': 4999,
      'billing_cycle': 'once',
      'category': 'one_time',
      'currency': 'INR',
    });

    expect(plan.category, PlanCategory.oneTime);
    expect(plan.priceAmount, 2999);
    expect(plan.originalPriceAmount, 4999);
    expect(plan.discountPercent, 40);
    expect(plan.billingPeriodLabel, 'once');
  });

  test('treats subscription and autopay as the same recurring category', () {
    expect(
      PlanModel.fromJson({'id': 'a', 'type': 'upi_autopay'}).category,
      PlanCategory.recurring,
    );
    expect(
      PlanModel.fromJson({'id': 'b', 'plan_type': 'subscription'}).category,
      PlanCategory.recurring,
    );
    expect(
      PlanModel.fromJson({'id': 'c', 'category': 'lifetime'}).category,
      PlanCategory.oneTime,
    );
  });
}
