/// Shared email validation helpers for auth flows (register, login,
/// forgot-password). Keeps validation consistent across screens and
/// avoids client-side inconsistencies that force users to discover
/// format errors only after the Firebase request fails.
abstract final class EmailValidator {
  static final RegExp _pattern = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns `true` when [value] looks like a well-formed email
  /// address. Trims surrounding whitespace before matching.
  static bool isValid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return _pattern.hasMatch(trimmed);
  }

  /// Form-validator friendly wrapper. Returns `null` when the email
  /// is valid, or a localized error message otherwise.
  ///
  /// Use as `validator: EmailValidator.validate` in `TextFormField`.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-mail obrigatório';
    }
    if (!_pattern.hasMatch(value.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }
}
