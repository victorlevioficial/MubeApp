import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/utils/category_normalizer.dart';

void main() {
  group('CategoryNormalizer.resolveCategories', () {
    test('maps legacy crew with production role to production', () {
      final categories = CategoryNormalizer.resolveCategories(
        rawCategories: const ['crew'],
        rawRoles: const ['Diretor Musical'],
      );

      expect(categories, contains('production'));
      expect(categories, isNot(contains('stage_tech')));
      expect(categories, isNot(contains('crew')));
    });

    test('maps legacy crew with stage tech role to stage_tech', () {
      final categories = CategoryNormalizer.resolveCategories(
        rawCategories: const ['crew'],
        rawRoles: const ['Backline Tech'],
      );

      expect(categories, contains('stage_tech'));
      expect(categories, isNot(contains('production')));
      expect(categories, isNot(contains('crew')));
    });

    test('preserves ambiguous legacy crew without recognized roles', () {
      final categories = CategoryNormalizer.resolveCategories(
        rawCategories: const ['crew'],
        rawRoles: const ['Funcao Customizada'],
      );

      expect(categories, ['crew']);
    });
  });

  group('CategoryNormalizer.isPureTechnician', () {
    test('treats production as musician', () {
      final isPureTechnician = CategoryNormalizer.isPureTechnician(
        rawCategories: const ['production'],
        rawRoles: const ['Mixagem'],
      );

      expect(isPureTechnician, isFalse);
    });

    test('treats stage_tech only profile as technician', () {
      final isPureTechnician = CategoryNormalizer.isPureTechnician(
        rawCategories: const ['stage_tech'],
        rawRoles: const ['Técnico de Monitor'],
      );

      expect(isPureTechnician, isTrue);
    });

    test('treats mixed singer and stage_tech profile as musician', () {
      final isPureTechnician = CategoryNormalizer.isPureTechnician(
        rawCategories: const ['singer', 'stage_tech'],
        rawRoles: const ['Técnico de Monitor'],
      );

      expect(isPureTechnician, isFalse);
    });
  });
}
