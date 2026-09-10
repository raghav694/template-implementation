import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/analytics/analytics_events.dart';
import 'package:app_template/core/analytics/analytics_service.dart';
import 'package:app_template/core/state/async_value.dart';
import 'package:app_template/core/utils/usecase.dart';
import 'package:app_template/features/auth/domain/usecases/auth_usecases.dart';
import 'package:app_template/features/auth/presentation/bloc/login_screen_analytics_guard.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_bloc.dart';
import 'package:app_template/features/auth/presentation/bloc/phone_auth_event.dart';

class SignOutCubit extends Cubit<AsyncValue<void>> {
  SignOutCubit({
    required SignOutUseCase signOutUseCase,
    required AnalyticsService analytics,
    required PhoneAuthBloc phoneAuthBloc,
  }) : _signOutUseCase = signOutUseCase,
       _analytics = analytics,
       _phoneAuthBloc = phoneAuthBloc,
       super(const AsyncData(null));

  final SignOutUseCase _signOutUseCase;
  final AnalyticsService _analytics;
  final PhoneAuthBloc _phoneAuthBloc;

  Future<void> signOut() async {
    emit(const AsyncLoading());

    final result = await _signOutUseCase(const NoParams());

    result.fold((failure) => emit(AsyncError(failure, StackTrace.current)), (
      _,
    ) {
      _analytics.logEvent(AnalyticsEvents.signOut);
      _analytics.logEvent(AnalyticsEvents.logout);
      _analytics.reset();
      _phoneAuthBloc.add(const PhoneAuthReset());
      LoginScreenAnalyticsGuard.reset();
      TruecallerAutoLaunchGuard.reset();
      emit(const AsyncData(null));
    });
  }
}
