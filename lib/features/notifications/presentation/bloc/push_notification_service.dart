import 'dart:async';

import 'package:app_template/core/constants/route_paths.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:app_template/core/firebase/firebase_initializer.dart';
import 'package:app_template/core/utils/usecase.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:app_template/features/notifications/data/datasources/fcm_remote_datasource_impl.dart';
import 'package:app_template/features/notifications/data/datasources/fcm_token_remote_datasource_impl.dart';
import 'package:app_template/features/notifications/data/repositories/push_notification_repository_impl.dart';
import 'package:app_template/features/notifications/domain/entities/notification_payload.dart';
import 'package:app_template/features/notifications/domain/repositories/push_notification_repository.dart';
import 'package:app_template/features/notifications/domain/usecases/push_notification_usecases.dart';
import 'package:app_template/features/notifications/presentation/bloc/foreground_notification_cubit.dart';
import 'package:app_template/features/notifications/presentation/bloc/pending_notification_cubit.dart';

class PushNotificationService {
  PushNotificationService({
    required AuthCubit authCubit,
    required ForegroundNotificationCubit foreground,
    required PendingNotificationCubit pendingNavigation,
  }) : _authCubit = authCubit,
       _foreground = foreground,
       _pendingNavigation = pendingNavigation;

  final AuthCubit _authCubit;
  final ForegroundNotificationCubit _foreground;
  final PendingNotificationCubit _pendingNavigation;

  PushNotificationRepository? _repository;
  RequestNotificationPermissionUseCase? _requestPermission;
  SyncFcmTokenUseCase? _syncFcmToken;
  ClearFcmTokenUseCase? _clearFcmToken;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<NotificationPayload>? _foregroundSubscription;
  StreamSubscription<NotificationPayload>? _openSubscription;
  StreamSubscription<dynamic>? _authSubscription;
  String? _activeUserId;
  User? _lastUser;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    if (!FirebaseInitializer.isInitialized) {
      return;
    }

    final repository = PushNotificationRepositoryImpl(
      FcmRemoteDataSourceImpl(),
      FcmTokenRemoteDataSourceImpl(),
    );
    _repository = repository;
    _requestPermission = RequestNotificationPermissionUseCase(repository);
    _syncFcmToken = SyncFcmTokenUseCase(repository);
    _clearFcmToken = ClearFcmTokenUseCase(repository);

    _authSubscription = _authCubit.stream.listen((_) => _onAuthChanged());
    _onAuthChanged();
  }

  void _onAuthChanged() {
    final previousUser = _lastUser;
    final nextUser = _authCubit.state.valueOrNull;
    _lastUser = nextUser;

    if (nextUser != null) {
      unawaited(_startForUser(nextUser.id));
    } else if (previousUser != null) {
      unawaited(_stopForUser(previousUser.id));
    }
  }

  Future<void> _startForUser(String userId) async {
    if (_activeUserId == userId) {
      return;
    }

    if (_activeUserId != null && _activeUserId != userId) {
      await _stopForUser(_activeUserId!);
    }

    _activeUserId = userId;
    await _disposeSubscriptions();

    await _requestPermission!(const NoParams());
    await _syncFcmToken!(SyncFcmTokenParams(userId: userId));

    final repository = _repository!;

    _tokenRefreshSubscription = repository.watchTokenRefresh().listen(
      (token) async {
        if (_activeUserId == null) {
          return;
        }
        final result = await repository.saveFcmToken(
          userId: _activeUserId!,
          token: token,
        );
        result.fold(
          (failure) => debugPrint('FCM token sync failed: ${failure.message}'),
          (_) {},
        );
      },
      onError: (Object error) {
        debugPrint('FCM token refresh failed: $error');
      },
    );

    _foregroundSubscription = repository.watchForegroundNotifications().listen(
      (payload) {
        _foreground.show(payload);
      },
      onError: (Object error) {
        debugPrint('Foreground notification stream failed: $error');
      },
    );

    _openSubscription = repository.watchNotificationOpens().listen(
      (payload) {
        _pendingNavigation.set(payload);
      },
      onError: (Object error) {
        debugPrint('Notification open stream failed: $error');
      },
    );

    final initialResult = await repository.getInitialNotification();
    initialResult.fold((_) {}, (payload) {
      if (payload != null) {
        _pendingNavigation.set(payload);
      }
    });
  }

  Future<void> _stopForUser(String userId) async {
    await _clearFcmToken!(ClearFcmTokenParams(userId: userId));
    _activeUserId = null;
    await _disposeSubscriptions();
  }

  Future<void> _disposeSubscriptions() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _openSubscription = null;
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _disposeSubscriptions();
  }
}

/// Navigates using the raw [NotificationPayload.route] path sent by the
/// backend (e.g. `/` or `/profile`).
///
/// Relative values like `paywall` are rewritten to `/paywall` so go_router
/// cannot nest them under the current location (`/paywall/paywall`).
void navigateFromNotificationPayload(
  GoRouter router,
  NotificationPayload payload,
) {
  final route = payload.route;
  if (route == null || route.isEmpty) {
    return;
  }

  router.go(RoutePaths.absolute(route));
}
