import 'package:fpdart/fpdart.dart';

import 'package:app_template/core/error/failures.dart';
import 'package:app_template/core/utils/usecase.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/auth/domain/repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  WatchAuthStateUseCase(this.repository);

  final AuthRepository repository;

  Stream<User?> call() => repository.authStateChanges();
}

class SendPhoneOtpUseCase implements UseCase<String, SendPhoneOtpParams> {
  SendPhoneOtpUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, String>> call(SendPhoneOtpParams params) {
    return repository.sendPhoneVerification(params.phoneNumber);
  }
}

class SendPhoneOtpParams {
  const SendPhoneOtpParams(this.phoneNumber);

  final String phoneNumber;
}

class VerifyPhoneOtpUseCase implements UseCase<User, VerifyPhoneOtpParams> {
  VerifyPhoneOtpUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(VerifyPhoneOtpParams params) {
    return repository.verifyPhoneOtp(
      verificationId: params.verificationId,
      smsCode: params.smsCode,
    );
  }
}

class VerifyPhoneOtpParams {
  const VerifyPhoneOtpParams({
    required this.verificationId,
    required this.smsCode,
  });

  final String verificationId;
  final String smsCode;
}

class VerifyTruecallerLoginUseCase
    implements UseCase<User, VerifyTruecallerLoginParams> {
  VerifyTruecallerLoginUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(VerifyTruecallerLoginParams params) {
    return repository.verifyTruecallerLogin(
      authorizationCode: params.authorizationCode,
      codeVerifier: params.codeVerifier,
    );
  }
}

class VerifyTruecallerLoginParams {
  const VerifyTruecallerLoginParams({
    required this.authorizationCode,
    required this.codeVerifier,
  });

  final String authorizationCode;
  final String codeVerifier;
}

class SignOutUseCase implements UseCase<void, NoParams> {
  SignOutUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.signOut();
  }
}

class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
  GetCurrentUserUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, User?>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
