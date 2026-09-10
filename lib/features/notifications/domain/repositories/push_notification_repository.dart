import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/notifications/domain/entities/notification_payload.dart';

abstract class PushNotificationRepository {
  Future<Either<Failure, bool>> requestPermission();

  Future<Either<Failure, String?>> getFcmToken();

  Stream<String> watchTokenRefresh();

  Stream<NotificationPayload> watchForegroundNotifications();

  Stream<NotificationPayload> watchNotificationOpens();

  Future<Either<Failure, NotificationPayload?>> getInitialNotification();

  Future<Either<Failure, void>> saveFcmToken({
    required String userId,
    required String token,
  });

  Future<Either<Failure, void>> clearFcmToken(String userId);
}
