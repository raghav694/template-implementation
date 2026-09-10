import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:app_template/core/config/app_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await AppConfig.initializeForBackground();
  // Background messages are handled by the OS notification tray.
  // Deep-link navigation is handled when the user taps the notification.
}
