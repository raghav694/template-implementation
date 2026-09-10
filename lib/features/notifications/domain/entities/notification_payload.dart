import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_payload.freezed.dart';

@freezed
abstract class NotificationPayload with _$NotificationPayload {
  const factory NotificationPayload({
    String? title,
    String? body,
    String? route,
  }) = _NotificationPayload;

  const NotificationPayload._();

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    return NotificationPayload(
      title: data['title'] as String?,
      body: data['body'] as String?,
      route: data['route'] as String?,
    );
  }

  bool get hasDeepLink => route != null && route!.isNotEmpty;
}
