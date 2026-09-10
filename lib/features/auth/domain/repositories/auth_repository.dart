import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();

  Future<Either<Failure, String>> sendPhoneVerification(String phoneNumber);

  Future<Either<Failure, User>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<Either<Failure, User>> verifyTruecallerLogin({
    required String authorizationCode,
    required String codeVerifier,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, User?>> getCurrentUser();
}
