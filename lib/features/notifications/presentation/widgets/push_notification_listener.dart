import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:app_template/config/app_identity.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/notifications/domain/entities/notification_payload.dart';
import 'package:app_template/features/notifications/presentation/bloc/foreground_notification_cubit.dart';
import 'package:app_template/features/notifications/presentation/bloc/pending_notification_cubit.dart';
import 'package:app_template/features/notifications/presentation/bloc/push_notification_service.dart';

class PushNotificationListener extends StatelessWidget {
  const PushNotificationListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForegroundNotificationCubit, NotificationPayload?>(
      listener: (context, payload) {
        if (payload == null) return;

        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;

        final title = payload.title ?? AppIdentity.appName;
        final body = payload.body ?? 'New update available';

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '$title · $body',
              style: AppTypography.textTheme.bodyMedium,
            ),
            action: payload.hasDeepLink
                ? SnackBarAction(
                    label: 'Open',
                    onPressed: () {
                      navigateFromNotificationPayload(
                        getIt<GoRouter>(),
                        payload,
                      );
                    },
                  )
                : null,
          ),
        );
        context.read<ForegroundNotificationCubit>().clear();
      },
      child: BlocListener<PendingNotificationCubit, NotificationPayload?>(
        listener: (context, payload) {
          if (payload == null) return;
          navigateFromNotificationPayload(getIt<GoRouter>(), payload);
          context.read<PendingNotificationCubit>().clear();
        },
        child: child,
      ),
    );
  }
}
