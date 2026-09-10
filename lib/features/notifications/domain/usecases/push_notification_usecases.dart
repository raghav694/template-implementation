import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/utils/usecase.dart';
import 'package:app_template/features/notifications/domain/repositories/push_notification_repository.dart';

class RequestNotificationPermissionUseCase implements UseCase<bool, NoParams> {
  RequestNotificationPermissionUseCase(this.repository);

  final PushNotificationRepository repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.requestPermission();
  }
}

class SyncFcmTokenUseCase implements UseCase<void, SyncFcmTokenParams> {
  SyncFcmTokenUseCase(this.repository);

  final PushNotificationRepository repository;

  @override
  Future<Either<Failure, void>> call(SyncFcmTokenParams params) async {
    final tokenResult = await repository.getFcmToken();
    if (tokenResult case Left(value: final failure)) {
      return Left(failure);
    }

    final token = switch (tokenResult) {
      Right(value: final value) => value,
      Left() => null,
    };

    if (token == null || token.isEmpty) {
      return const Right(null);
    }

    return repository.saveFcmToken(userId: params.userId, token: token);
  }
}

class SyncFcmTokenParams {
  const SyncFcmTokenParams({required this.userId});

  final String userId;
}

class ClearFcmTokenUseCase implements UseCase<void, ClearFcmTokenParams> {
  ClearFcmTokenUseCase(this.repository);

  final PushNotificationRepository repository;

  @override
  Future<Either<Failure, void>> call(ClearFcmTokenParams params) {
    return repository.clearFcmToken(params.userId);
  }
}

class ClearFcmTokenParams {
  const ClearFcmTokenParams({required this.userId});

  final String userId;
}
