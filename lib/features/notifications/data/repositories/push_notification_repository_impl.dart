import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/notifications/domain/entities/notification_payload.dart';
import 'package:app_template/features/notifications/domain/repositories/push_notification_repository.dart';
import 'package:app_template/features/notifications/data/datasources/fcm_remote_datasource.dart';
import 'package:app_template/features/notifications/data/datasources/fcm_token_remote_datasource.dart';

class PushNotificationRepositoryImpl implements PushNotificationRepository {
  PushNotificationRepositoryImpl(this._fcmDataSource, this._tokenDataSource);

  final FcmRemoteDataSource _fcmDataSource;
  final FcmTokenRemoteDataSource _tokenDataSource;

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    try {
      final granted = await _fcmDataSource.requestPermission();
      return Right(granted);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getFcmToken() async {
    try {
      final token = await _fcmDataSource.getToken();
      return Right(token);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Stream<String> watchTokenRefresh() => _fcmDataSource.watchTokenRefresh();

  @override
  Stream<NotificationPayload> watchForegroundNotifications() =>
      _fcmDataSource.watchForegroundNotifications();

  @override
  Stream<NotificationPayload> watchNotificationOpens() =>
      _fcmDataSource.watchNotificationOpens();

  @override
  Future<Either<Failure, NotificationPayload?>> getInitialNotification() async {
    try {
      final payload = await _fcmDataSource.getInitialNotification();
      return Right(payload);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveFcmToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _tokenDataSource.saveFcmToken(userId: userId, token: token);
      return const Right(null);
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearFcmToken(String userId) async {
    try {
      await _tokenDataSource.clearFcmToken(userId);
      return const Right(null);
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
