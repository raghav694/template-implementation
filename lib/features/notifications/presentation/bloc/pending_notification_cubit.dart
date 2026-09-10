import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/features/notifications/domain/entities/notification_payload.dart';

class PendingNotificationCubit extends Cubit<NotificationPayload?> {
  PendingNotificationCubit() : super(null);

  void set(NotificationPayload payload) => emit(payload);

  void clear() => emit(null);
}
