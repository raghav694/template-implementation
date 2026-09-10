import 'package:app_template/features/paywall/domain/entities/subscription.dart';

abstract class SubscriptionRemoteDataSource {
  Future<Subscription?> getSubscription(String userId);

  Future<void> cancelSubscription(String userId);
}
