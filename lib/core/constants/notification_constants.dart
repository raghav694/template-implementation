import 'package:app_template/config/app_identity.dart';

class NotificationConstants {
  NotificationConstants._();

  static const androidChannelId = 'app_default';
  static String get androidChannelName => '${AppIdentity.appName} Updates';
  static const androidChannelDescription = 'Account and product updates';
}
