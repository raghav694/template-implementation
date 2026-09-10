import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String phone,
    String? displayName,
    String? email,
    @Default('free') String entitlement,
    @Default(false) bool hasPurchased,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) = _User;

  /// Non-`free` profile entitlement that has not passed [expiresAt].
  ///
  /// A past [expiresAt] is expired even if [entitlement] has not flipped yet
  /// (same cutoff as Capslock `validity_end_at`). Unset / sentinel dates are
  /// ignored.
  bool get isPremium {
    final value = entitlement.trim().toLowerCase();
    if (value.isEmpty || value == 'free') return false;
    final end = expiresAt;
    if (end != null && end.year >= 2000 && !end.isAfter(DateTime.now())) {
      return false;
    }
    return true;
  }
}
