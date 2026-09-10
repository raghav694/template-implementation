abstract class FcmTokenRemoteDataSource {
  Future<void> saveFcmToken({required String userId, required String token});

  Future<void> clearFcmToken(String userId);
}
