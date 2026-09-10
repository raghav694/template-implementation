import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';

import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/payments/payments_config.dart';
import 'package:app_template/features/paywall/data/datasources/subscription_remote_datasource.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSourceImpl(this._client);

  final CheckoutClient _client;

  @override
  Future<Subscription?> getSubscription(String userId) async {
    _ensureConfigured();
    try {
      final response = await _client.getUserSubscription(
        GetUserSubscriptionRequest(
          tenantId: AppConfig.paymentsTenantId,
          externalId: userId,
        ),
      );
      if (response.id.isEmpty) return null;
      return _toEntity(response, userId);
    } on NetworkException {
      rethrow;
    } on StateError catch (error) {
      if (_isNotFound(error.message)) return null;
      throw ServerException(error.message);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(error.toString());
    }
  }

  @override
  Future<void> cancelSubscription(String userId) async {
    _ensureConfigured();
    try {
      final current = await _client.getUserSubscription(
        GetUserSubscriptionRequest(
          tenantId: AppConfig.paymentsTenantId,
          externalId: userId,
        ),
      );
      if (current.id.isEmpty) {
        throw const ServerException('No subscription found to cancel');
      }
      await _client.cancelSubscription(
        CancelSubscriptionRequest(
          tenantId: AppConfig.paymentsTenantId,
          subscriptionId: current.id,
        ),
      );
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } on StateError catch (error) {
      throw ServerException(error.message);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  void _ensureConfigured() {
    if (!AppConfig.hasPaymentsConfig) {
      throw const ServerException(
        'Capslock Payments is not configured. Set PAYMENTS_BASE_URL and '
        'PAYMENTS_TENANT_ID.',
      );
    }
  }

  static Subscription _toEntity(
    GetUserSubscriptionResponse response,
    String userId,
  ) {
    final nextBillingAt = _parseDate(response.nextBillingAt);
    final validityEndAt = _parseDate(response.validityEndAt);
    return Subscription(
      userId: response.externalId.isNotEmpty ? response.externalId : userId,
      status: PaymentsConfig.toAppSubscriptionStatus(response.status),
      plan: response.planId,
      // Access lasts until validity_end_at, not the next charge time.
      currentEnd: validityEndAt ?? nextBillingAt,
      chargeAt: nextBillingAt,
      gatewaySubscriptionId: response.gatewaySubscriptionId.isEmpty
          ? null
          : response.gatewaySubscriptionId,
      provider: response.provider.isEmpty ? null : response.provider,
    );
  }

  static DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static bool _isNotFound(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not found') ||
        normalized.contains('http 404') ||
        normalized == '404';
  }
}
