import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_template/features/auth/domain/entities/user.dart';

part 'user_model.freezed.dart';

@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String phone,
    String? displayName,
    String? email,
    @Default('free') String entitlement,
    @Default(false) bool hasPurchased,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? fcmToken,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      phone: json['phone_number'] as String? ?? json['phone'] as String? ?? '',
      displayName: json['name'] as String? ?? json['displayName'] as String?,
      email: json['email'] as String?,
      entitlement: json['entitlement'] as String? ?? 'free',
      hasPurchased: _boolFromJson(json['has_purchased'] ?? json['hasPurchased']),
      createdAt: _dateTimeFromJson(json['createdAt'] ?? json['created_at']),
      expiresAt: _dateTimeFromJson(
        json['validity_end_at'] ??
            json['validity_end'] ??
            json['expires_at'] ??
            json['expiresAt'],
      ),
      fcmToken: json['fcmToken'] as String? ?? json['fcm_token'] as String?,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      id: doc.id,
      phone: data['phone'] as String? ?? '',
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      entitlement: data['entitlement'] as String? ?? 'free',
      hasPurchased: _boolFromJson(
        data['has_purchased'] ?? data['hasPurchased'],
      ),
      createdAt: _timestampToDateTime(data['createdAt']),
      expiresAt: _timestampToDateTime(
        data['validity_end_at'] ?? data['expires_at'] ?? data['expiresAt'],
      ),
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toStoreJson() => {
    'id': id,
    'phone_number': phone,
    'name': displayName,
    'entitlement': entitlement,
    'has_purchased': hasPurchased,
    if (expiresAt != null) 'validity_end_at': expiresAt!.toIso8601String(),
  };

  User toEntity() => User(
    id: id,
    phone: phone,
    displayName: displayName,
    email: email,
    entitlement: entitlement,
    hasPurchased: hasPurchased,
    createdAt: createdAt,
    expiresAt: expiresAt,
  );

  static bool _boolFromJson(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return _dateTimeFromJson(value);
  }

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }
}
