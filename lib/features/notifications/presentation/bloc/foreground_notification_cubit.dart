import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/features/notifications/domain/entities/notification_payload.dart';

class ForegroundNotificationCubit extends Cubit<NotificationPayload?> {
  ForegroundNotificationCubit() : super(null);

  void show(NotificationPayload payload) => emit(payload);

  void clear() => emit(null);
}
