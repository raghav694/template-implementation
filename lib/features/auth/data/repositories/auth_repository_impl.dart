import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_template/features/auth/data/datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<User?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map(
      (userModel) => userModel?.toEntity(),
    );
  }

  @override
  Future<Either<Failure, String>> sendPhoneVerification(
    String phoneNumber,
  ) async {
    try {
      final verificationId = await _remoteDataSource.sendPhoneVerification(
        phoneNumber,
      );
      return Right(verificationId);
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final userModel = await _remoteDataSource.verifyPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return Right(userModel.toEntity());
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> verifyTruecallerLogin({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    try {
      final userModel = await _remoteDataSource.verifyTruecallerLogin(
        authorizationCode: authorizationCode,
        codeVerifier: codeVerifier,
      );
      return Right(userModel.toEntity());
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUserDocument();
      return Right(userModel?.toEntity());
    } on AuthException catch (error) {
      return Left(AuthFailure(error.message));
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
