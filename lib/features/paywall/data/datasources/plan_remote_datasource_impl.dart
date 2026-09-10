import 'package:capslock_payments_sdk/capslock_payments_sdk.dart' as payments;

import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/features/paywall/data/datasources/plan_remote_datasource.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';

/// Loads catalog plans from Capslock Payments (not the app REST `/api/v1/plans`).
class PlanRemoteDataSourceImpl implements PlanRemoteDataSource {
  PlanRemoteDataSourceImpl(this._client);

  final payments.CheckoutClient _client;

  @override
  Future<Plan> fetchPlan(String planId) async {
    _ensureConfigured();
    try {
      final remote = await _client.getPlan(
        payments.GetPlanRequest(
          tenantId: AppConfig.paymentsTenantId,
          planId: planId,
        ),
      );
      return toDomainPlan(remote);
    } on NetworkException {
      rethrow;
    } on StateError catch (error) {
      if (_isNotFound(error.message)) {
        final match = await _planFromList(planId);
        if (match != null) return match;
        throw const ServerException('Plan configuration not found');
      }
      throw ServerException(error.message);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(error.toString());
    }
  }

  @override
  Future<List<Plan>> fetchPlans({String? source}) async {
    _ensureConfigured();
    try {
      final response = await _client.listPlans(
        payments.ListPlansRequest(
          tenantId: AppConfig.paymentsTenantId,
          limit: 50,
        ),
      );
      return response.plans.map(toDomainPlan).toList();
    } on NetworkException {
      rethrow;
    } on StateError catch (error) {
      throw ServerException(error.message);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(error.toString());
    }
  }

  Future<Plan?> _planFromList(String planId) async {
    final catalog = await fetchPlans();
    for (final plan in catalog) {
      if (plan.id == planId) return plan;
    }
    return null;
  }

  void _ensureConfigured() {
    if (!AppConfig.hasPaymentsConfig) {
      throw const ServerException(
        'Capslock Payments is not configured. Set PAYMENTS_BASE_URL and '
        'PAYMENTS_TENANT_ID.',
      );
    }
  }

  static bool _isNotFound(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not found') ||
        normalized.contains('http 404') ||
        normalized == '404';
  }
}

Plan toDomainPlan(payments.Plan plan) {
  final interval = plan.interval.trim().toLowerCase();
  final type = plan.type.trim().toLowerCase();
  final oneTime =
      type.contains('one_time') ||
      type.contains('onetime') ||
      interval.contains('one_time') ||
      interval.contains('onetime') ||
      interval == 'once' ||
      interval.contains('lifetime');
  final yearly = interval.startsWith('year') || interval.startsWith('annual');
  final amount = plan.amountMinor <= 0 ? 0 : (plan.amountMinor / 100).round();
  final trialDays = plan.hasTrial ? plan.trialDuration : 0;
  final trialMinor = plan.authorizationAmountMinor;
  final trialAmount = trialMinor != null && trialMinor > 0
      ? (trialMinor / 100).round()
      : _rupeesFromMetadata(plan, const ['trial_amount_inr', 'trial_amount']);
  return Plan(
    id: plan.id,
    label:
        plan.metadataValue(const ['label', 'name', 'title']) ??
        (oneTime
            ? 'Lifetime'
            : yearly
            ? 'Yearly Premium'
            : 'Monthly Premium'),
    priceAmount: amount,
    originalPriceAmount: _rupeesFromMetadata(plan, const [
      'original_price_inr',
      'original_price',
      'mrp',
    ]),
    billingCycle: oneTime
        ? 'once'
        : yearly
        ? 'year'
        : 'month',
    category: oneTime ? PlanCategory.oneTime : PlanCategory.recurring,
    currencyCode: plan.currency.isEmpty ? 'INR' : plan.currency,
    trialDays: trialDays,
    trialAmount: trialDays > 0 ? trialAmount : null,
    videoUrl: plan.metadataValue(const [
      'video_url',
      'videoUrl',
      'plan_video_url',
    ]),
  );
}

int? _rupeesFromMetadata(payments.Plan plan, List<String> keys) {
  final raw = plan.metadataValue(keys);
  if (raw == null) return null;
  final parsed = num.tryParse(raw);
  if (parsed == null || parsed <= 0) return null;
  return parsed.round();
}
