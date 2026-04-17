/// Strict validation helpers for the `dd/mm/yyyy` birth-date input
/// used by the onboarding flow. Lives outside the widget so it can
/// be unit-tested without a `BuildContext` and reused by other flows
/// that need the same age gate.
abstract final class BirthDateValidator {
  /// Parses a `dd/mm/yyyy` string strictly and returns `null` when
  /// the string is not a valid calendar date. Rejects values that
  /// `DateTime` would silently normalise (e.g. `30/02/2024` becoming
  /// `01/03/2024`).
  static DateTime? parseStrict(String rawText, {DateTime? today}) {
    final text = rawText.trim();
    final parts = text.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    final currentYear = (today ?? DateTime.now()).year;
    if (year < 1900 || year > currentYear) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final parsed = DateTime(year, month, day);
    if (parsed.year != year ||
        parsed.month != month ||
        parsed.day != day) {
      return null;
    }
    return parsed;
  }

  /// Whole-year difference between [from] and [to], rounded down.
  /// Defaults `to` to `DateTime.now()` so callers can ignore the
  /// argument in production code.
  static int yearsBetween(DateTime from, {DateTime? to}) {
    final reference = to ?? DateTime.now();
    var years = reference.year - from.year;
    if (reference.month < from.month ||
        (reference.month == from.month && reference.day < from.day)) {
      years--;
    }
    return years;
  }

  /// True when [birthDate] makes the user 18 or older relative to
  /// [today] (defaults to `DateTime.now()`).
  static bool isAdult(DateTime birthDate, {DateTime? today}) {
    return yearsBetween(birthDate, to: today) >= 18;
  }
}
