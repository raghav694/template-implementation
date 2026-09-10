enum PhoneAuthStep { phone, otp }

class PhoneAuthState {
  const PhoneAuthState({
    this.step = PhoneAuthStep.phone,
    this.isLoading = false,
    this.error,
    this.phoneNumber,
    this.verificationId,
  });

  final PhoneAuthStep step;
  final bool isLoading;
  final Object? error;
  final String? phoneNumber;
  final String? verificationId;

  PhoneAuthState copyWith({
    PhoneAuthStep? step,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    String? phoneNumber,
    String? verificationId,
  }) {
    return PhoneAuthState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}
