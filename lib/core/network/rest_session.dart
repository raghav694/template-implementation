import 'dart:async';

import 'package:app_template/features/auth/data/models/user_model.dart';

/// In-memory REST auth session. [authStateChanges] is driven from here
/// after Phone/OTP verify succeeds.
class RestSession {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _user;

  UserModel? get user => _user;

  Stream<UserModel?> get changes async* {
    yield _user;
    yield* _controller.stream;
  }

  /// Sets the current user without broadcasting. Used while restoring a
  /// cached session so the first [changes] yield is already populated.
  void restore(UserModel? user) {
    _user = user;
  }

  void emit(UserModel? user) {
    _user = user;
    if (!_controller.isClosed) {
      _controller.add(user);
    }
  }

  Future<void> dispose() => _controller.close();
}
