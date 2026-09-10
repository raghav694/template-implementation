import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/features/notifications/data/datasources/fcm_token_remote_datasource.dart';

class FcmTokenRemoteDataSourceImpl implements FcmTokenRemoteDataSource {
  FcmTokenRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveFcmToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  @override
  Future<void> clearFcmToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  Exception _mapFirebaseException(FirebaseException error) {
    if (error.code == 'unavailable' || error.code == 'network-request-failed') {
      return NetworkException(error.message ?? 'Network connection failed');
    }
    return ServerException(error.message ?? 'Firestore error occurred');
  }
}
