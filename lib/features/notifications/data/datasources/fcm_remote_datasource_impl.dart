import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/features/notifications/domain/entities/notification_payload.dart';
import 'package:app_template/features/notifications/data/datasources/fcm_remote_datasource.dart';

class FcmRemoteDataSourceImpl implements FcmRemoteDataSource {
  FcmRemoteDataSourceImpl({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      return _messaging.getToken();
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  @override
  Stream<String> watchTokenRefresh() => _messaging.onTokenRefresh;

  @override
  Stream<NotificationPayload> watchForegroundNotifications() {
    return FirebaseMessaging.onMessage.map(_mapMessage);
  }

  @override
  Stream<NotificationPayload> watchNotificationOpens() {
    return FirebaseMessaging.onMessageOpenedApp.map(_mapMessage);
  }

  @override
  Future<NotificationPayload?> getInitialNotification() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message == null) {
        return null;
      }
      return _mapMessage(message);
    } catch (error) {
      throw ServerException(error.toString());
    }
  }

  NotificationPayload _mapMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    if (message.notification?.title != null) {
      data['title'] = message.notification!.title;
    }
    if (message.notification?.body != null) {
      data['body'] = message.notification!.body;
    }

    return NotificationPayload.fromData(data);
  }
}
