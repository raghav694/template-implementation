import 'package:app_template/features/paywall/data/datasources/subscription_remote_datasource.dart';
import 'package:app_template/features/paywall/domain/entities/subscription.dart';

class FakeSubscriptionRemoteDataSource implements SubscriptionRemoteDataSource {
  FakeSubscriptionRemoteDataSource({this.subscription, this.getError});

  Subscription? subscription;
  Object? getError;
  Object? cancelError;
  var cancelCalls = 0;

  @override
  Future<Subscription?> getSubscription(String userId) async {
    final error = getError;
    if (error != null) throw error;
    return subscription;
  }

  @override
  Future<void> cancelSubscription(String userId) async {
    cancelCalls += 1;
    final error = cancelError;
    if (error != null) throw error;
  }
}
