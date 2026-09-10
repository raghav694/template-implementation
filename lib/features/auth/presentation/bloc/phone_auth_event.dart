sealed class PhoneAuthEvent {
  const PhoneAuthEvent();
}

class PhoneAuthOtpRequested extends PhoneAuthEvent {
  const PhoneAuthOtpRequested(this.phone);

  final String phone;
}

class PhoneAuthOtpResent extends PhoneAuthEvent {
  const PhoneAuthOtpResent(this.phone);

  final String phone;
}

class PhoneAuthOtpVerified extends PhoneAuthEvent {
  const PhoneAuthOtpVerified(this.otp);

  final String otp;
}

class PhoneAuthReset extends PhoneAuthEvent {
  const PhoneAuthReset();
}

class PhoneAuthTruecallerRequested extends PhoneAuthEvent {
  const PhoneAuthTruecallerRequested();
}
