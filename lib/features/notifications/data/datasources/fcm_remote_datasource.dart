import 'package:app_template/features/notifications/domain/entities/notification_payload.dart';

abstract class FcmRemoteDataSource {
  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> watchTokenRefresh();

  Stream<NotificationPayload> watchForegroundNotifications();

  Stream<NotificationPayload> watchNotificationOpens();

  Future<NotificationPayload?> getInitialNotification();
}
