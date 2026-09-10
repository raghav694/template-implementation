import 'package:flutter/services.dart';

/// Normalizes raw phone input to a canonical 10-digit Indian mobile number and
/// enforces that format inside a [TextField].
///
/// ### What it does on every keystroke / paste / autofill injection
///
/// 1. Strips every non-digit character (spaces, hyphens, `+`, parentheses, etc.).
/// 2. If the result is ≤ 10 digits, stores it as-is (mid-typing in progress).
/// 3. If the result is > 10 digits, delegates entirely to [normalize]: that
///    function strips the country-code prefix, takes the last 10 digits, and
///    validates the pattern.  Accepted if valid; rejected otherwise.
///    No attempt is made to infer *how* the value arrived — the formatter only
///    reasons about the *value*, not the input mechanism.
/// 4. Cursor is always placed at the end of the field.
///
/// ### Why `maxLength: 10` is removed
///
/// Flutter appends a [LengthLimitingTextInputFormatter] *after* all user
/// formatters.  When autofill injects "+919876543210" the digit-strip yields
/// "919876543210" (12 chars); the length limiter then takes the first 10 →
/// "9198765432" — a completely wrong number.  This formatter already caps at
/// 10 digits, making `maxLength` both redundant and harmful.
///
/// ### Static helper
///
/// [IndianPhoneInputFormatter.normalize] is the single normalization function
/// shared by the system-hint path, the submission guard, and this formatter,
/// so the exact same logic runs on every input path.
class IndianPhoneInputFormatter extends TextInputFormatter {
  static final RegExp _validPattern = RegExp(r'^\d{10}$');

  /// Returns a canonical 10-digit Indian mobile number extracted from [raw],
  /// or `null` if [raw] cannot be normalized to a valid number.
  ///
  /// Handles all common formats:
  /// - `9876543210`
  /// - `+919876543210` / `+91 98765 43210` / `+91-98765-43210`
  /// - `91 9876543210`
  /// - `09876543210`
  /// - numbers with parentheses, spaces, hyphens
  static String? normalize(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return null;
    final mobile = digits.substring(digits.length - 10);
    return _validPattern.hasMatch(mobile) ? mobile : null;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Field is being cleared — allow empty value.
    if (digits.isEmpty) return TextEditingValue.empty;

    // Within 10 digits: mid-typing in progress, store the raw digits as-is.
    if (digits.length <= 10) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }

    // More than 10 digits: normalize() is the single authority on what to do.
    // It strips the country-code prefix and validates the result.  If it
    // returns a canonical number we accept it; otherwise we reject the change.
    // This is deliberately agnostic about *how* the extra digits arrived
    // (paste, autofill, incremental keyboard suggestion — it doesn't matter).
    final normalized = normalize(newValue.text);
    if (normalized != null) {
      return TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    return oldValue;
  }
}
