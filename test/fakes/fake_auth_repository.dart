import 'package:fpdart/fpdart.dart';
import 'package:app_template/core/error/failures.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.truecallerFailure});

  User? user;
  Failure? truecallerFailure;
  Failure? sendOtpFailure;
  Failure? verifyOtpFailure;
  var truecallerCalls = 0;

  @override
  Stream<User?> authStateChanges() async* {
    yield user;
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return Right(user);
  }

  @override
  Future<Either<Failure, String>> sendPhoneVerification(
    String phoneNumber,
  ) async {
    final failure = sendOtpFailure;
    if (failure != null) return Left(failure);
    return const Right('fake-verification-id');
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    user = null;
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final failure = verifyOtpFailure;
    if (failure != null) return Left(failure);
    user = const User(id: 'fake-user', phone: '+919876543210');
    return Right(user!);
  }

  @override
  Future<Either<Failure, User>> verifyTruecallerLogin({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    truecallerCalls += 1;
    final failure = truecallerFailure;
    if (failure != null) return Left(failure);
    user = const User(id: 'fake-user', phone: '+919876543210');
    return Right(user!);
  }
}
