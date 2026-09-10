import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/core/utils/usecase.dart';
import 'package:app_template/features/auth/domain/entities/user.dart';
import 'package:app_template/features/auth/domain/usecases/auth_usecases.dart';

/// Session cubit. Emits the auth stream as [AsyncValue] for go_router redirects.
class AuthCubit extends Cubit<AsyncValue<User?>> {
  AuthCubit(
    this._watchAuthState, {
    GetCurrentUserUseCase? getCurrentUser,
  }) : _getCurrentUser = getCurrentUser,
       super(const AsyncLoading()) {
    _listen();
  }

  final WatchAuthStateUseCase _watchAuthState;
  final GetCurrentUserUseCase? _getCurrentUser;
  StreamSubscription<User?>? _subscription;
  Timer? _firstEventTimeout;

  void retry() {
    unawaited(_subscription?.cancel());
    _firstEventTimeout?.cancel();
    emit(const AsyncLoading());
    _listen();
  }

  /// Reloads the auth profile so entitlement / has_purchased stay current.
  Future<void> refreshProfile() async {
    final getCurrentUser = _getCurrentUser;
    if (getCurrentUser == null) return;
    final result = await getCurrentUser(const NoParams());
    result.fold((_) {}, (user) {
      if (!isClosed && user != null) emit(AsyncData(user));
    });
  }

  void _listen() {
    _subscription = _watchAuthState().listen(
      (user) {
        _firstEventTimeout?.cancel();
        if (!isClosed) emit(AsyncData(user));
      },
      onError: (Object error, StackTrace stackTrace) {
        _firstEventTimeout?.cancel();
        if (!isClosed) emit(AsyncError(error, stackTrace));
      },
      onDone: () {
        _firstEventTimeout?.cancel();
        if (!isClosed && state.isLoading) {
          emit(const AsyncData(null));
        }
      },
    );
    _firstEventTimeout = Timer(const Duration(seconds: 8), () {
      if (!isClosed && state.isLoading) {
        emit(const AsyncData(null));
      }
    });
  }

  @override
  Future<void> close() async {
    _firstEventTimeout?.cancel();
    await _subscription?.cancel();
    return super.close();
  }
}
