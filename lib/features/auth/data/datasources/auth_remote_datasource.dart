import 'package:app_template/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> authStateChanges();

  Future<String> sendPhoneVerification(String phoneNumber);

  Future<UserModel> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<UserModel> verifyTruecallerLogin({
    required String authorizationCode,
    required String codeVerifier,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUserDocument();
}
