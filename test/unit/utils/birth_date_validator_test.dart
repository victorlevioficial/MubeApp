import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/utils/birth_date_validator.dart';

void main() {
  group('BirthDateValidator.parseStrict', () {
    test('returns null for empty input', () {
      expect(BirthDateValidator.parseStrict(''), isNull);
      expect(BirthDateValidator.parseStrict('   '), isNull);
    });

    test('returns null when the format is wrong', () {
      expect(BirthDateValidator.parseStrict('1990-01-01'), isNull);
      expect(BirthDateValidator.parseStrict('01/01'), isNull);
      expect(BirthDateValidator.parseStrict('01/01/1990/extra'), isNull);
    });

    test('returns null when components are not numeric', () {
      expect(BirthDateValidator.parseStrict('aa/01/1990'), isNull);
      expect(BirthDateValidator.parseStrict('01/bb/1990'), isNull);
      expect(BirthDateValidator.parseStrict('01/01/cccc'), isNull);
    });

    test('rejects values that DateTime would silently normalize', () {
      // 30/02 is not a calendar date even though DateTime accepts it.
      expect(BirthDateValidator.parseStrict('30/02/2024'), isNull);
      // 31/04 does not exist in April.
      expect(BirthDateValidator.parseStrict('31/04/2024'), isNull);
    });

    test('rejects out-of-range months and years', () {
      expect(BirthDateValidator.parseStrict('01/13/2000'), isNull);
      expect(BirthDateValidator.parseStrict('01/00/2000'), isNull);
      expect(BirthDateValidator.parseStrict('01/01/1899'), isNull);
      final futureYear = DateTime.now().year + 1;
      expect(BirthDateValidator.parseStrict('01/01/$futureYear'), isNull);
    });

    test('parses a valid date', () {
      final parsed = BirthDateValidator.parseStrict('15/05/1995');
      expect(parsed, DateTime(1995, 5, 15));
    });
  });

  group('BirthDateValidator.isAdult', () {
    test('returns true for 18 years and one day', () {
      final today = DateTime(2026, 4, 17);
      final birth = DateTime(2008, 4, 16);
      expect(BirthDateValidator.isAdult(birth, today: today), isTrue);
    });

    test('returns false the day before the 18th birthday', () {
      final today = DateTime(2026, 4, 17);
      final birth = DateTime(2008, 4, 18);
      expect(BirthDateValidator.isAdult(birth, today: today), isFalse);
    });

    test('returns true exactly on the 18th birthday', () {
      final today = DateTime(2026, 4, 17);
      final birth = DateTime(2008, 4, 17);
      expect(BirthDateValidator.isAdult(birth, today: today), isTrue);
    });

    test('returns false for clearly underage', () {
      final today = DateTime(2026, 4, 17);
      final birth = DateTime(2015, 1, 1);
      expect(BirthDateValidator.isAdult(birth, today: today), isFalse);
    });
  });
}
