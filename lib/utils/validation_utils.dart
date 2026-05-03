class ValidationUtils {
  static const _cniPattern = r'^GN-\d{3}-\d{6}$';
  static const _guineaPhonePattern = r'^\+224[0-9]{8}$';

  static String? validateCniNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro CNI est requis.';
    }
    final normalized = value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(_cniPattern).hasMatch(normalized)) {
      return 'Le numéro CNI doit être au format GN-123-123456.';
    }
    return null;
  }

  static String? validateGuineaPhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis.';
    }
    final normalized = normalizePhoneNumber(value);
    if (!RegExp(_guineaPhonePattern).hasMatch(normalized)) {
      return 'Le numéro doit être au format +224XXXXXXXX.';
    }
    return null;
  }

  static String normalizePhoneNumber(String value) {
    var normalized = value.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (normalized.startsWith('00224')) {
      normalized = '+${normalized.substring(2)}';
    }
    if (normalized.startsWith('224') && !normalized.startsWith('+224')) {
      normalized = '+$normalized';
    }
    return normalized;
  }

  static String normalizeCniNumber(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }
}
