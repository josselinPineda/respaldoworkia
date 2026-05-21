class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r"^[A-Z0-9._%+\-']+@[A-Z0-9.\-]+\.[A-Z]{2,}$",
    caseSensitive: false,
  );

  /// Validates an email address.
  ///
  /// This is intentionally pragmatic (not fully RFC 5322).
  static bool isValidEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return _emailRegExp.hasMatch(v);
  }

  /// Normalizes a phone number to digits-only (keeps leading `+` optional).
  static String normalizePhoneDigits(String value) {
    final trimmed = value.trim();
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasPlus ? '+$digits' : digits;
  }

  /// Validates a phone number (E.164-ish).
  ///
  /// Accepts common separators/spaces.
  /// After stripping non-digits it requires a total of 8-15 digits.
  static bool isValidPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;

    // Allow only common phone symbols in user input.
    if (!RegExp(r'^[0-9+\-().\s]+$').hasMatch(trimmed)) return false;

    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 8 || digitsOnly.length > 15) return false;
    return true;
  }
}
