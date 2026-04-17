import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/constants/app_constants.dart' as app_constants;
import 'package:mube/src/core/domain/professional_roles.dart';
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

    test('preserves the new professional support subcategories', () {
      final categories = CategoryNormalizer.resolveCategories(
        rawCategories: const [
          'audiovisual',
          'education',
          'luthier',
          'performance',
        ],
        rawRoles: const [],
      );

      expect(
        categories,
        containsAll(const [
          'audiovisual',
          'education',
          'luthier',
          'performance',
        ]),
      );
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

  group('CategoryNormalizer.shouldRequireGenres', () {
    test('hides genres for audiovisual, education and luthier', () {
      expect(
        CategoryNormalizer.shouldRequireGenres(
          rawCategories: const ['audiovisual'],
          rawRoles: const [],
        ),
        isFalse,
      );
      expect(
        CategoryNormalizer.shouldRequireGenres(
          rawCategories: const ['education'],
          rawRoles: const [],
        ),
        isFalse,
      );
      expect(
        CategoryNormalizer.shouldRequireGenres(
          rawCategories: const ['luthier'],
          rawRoles: const [],
        ),
        isFalse,
      );
    });

    test('keeps genres required for performance', () {
      expect(
        CategoryNormalizer.shouldRequireGenres(
          rawCategories: const ['performance'],
          rawRoles: const [],
        ),
        isTrue,
      );
    });
  });

  group('CategoryNormalizer.isEligibleForHomeAndMatchpoint', () {
    test('excludes luthier-only profiles from Home and MatchPoint', () {
      expect(
        CategoryNormalizer.isEligibleForHomeAndMatchpoint(
          rawCategories: const ['luthier'],
          rawRoles: const [],
        ),
        isFalse,
      );
    });

    test('keeps instrumentalist plus luthier profiles eligible', () {
      expect(
        CategoryNormalizer.isEligibleForHomeAndMatchpoint(
          rawCategories: const ['instrumentalist', 'luthier'],
          rawRoles: const [],
        ),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------
  // PR 8 — paridade após reconciliar aliases com `professional_roles`.
  // Garante que o lookup centralizado em `professional_roles.dart`
  // continua reconhecendo todos os labels que o normalizer cobria
  // localmente antes da refatoração.
  // -------------------------------------------------------------------

  group('CategoryNormalizer.normalizeRoleId — paridade legacy/canonical', () {
    test('reconhece todos os labels canônicos de produção e stage tech', () {
      for (final label in app_constants.productionRoles) {
        final id = CategoryNormalizer.sanitize(label);
        expect(
          CategoryNormalizer.normalizeRoleId(label),
          id,
          reason: 'production role "$label"',
        );
        expect(
          CategoryNormalizer.isProductionRoleId(id),
          isTrue,
          reason: 'production role id "$id"',
        );
      }
      for (final label in app_constants.stageTechRoles) {
        final id = CategoryNormalizer.sanitize(label);
        expect(
          CategoryNormalizer.normalizeRoleId(label),
          id,
          reason: 'stage_tech role "$label"',
        );
        expect(
          CategoryNormalizer.isStageTechRoleId(id),
          isTrue,
          reason: 'stage_tech role id "$id"',
        );
      }
    });

    test(
      'reconhece labels legados de audiovisual/education/luthier/performance',
      () {
        final legacyLists = <String, List<String>>{
          'audiovisual': app_constants.audiovisualRoles,
          'education': app_constants.educationRoles,
          'luthier': app_constants.luthierRoles,
          'performance': app_constants.performanceRoles,
        };

        for (final entry in legacyLists.entries) {
          for (final label in entry.value) {
            final id = CategoryNormalizer.sanitize(label);
            expect(
              CategoryNormalizer.normalizeRoleId(label),
              id,
              reason: '${entry.key} legacy role "$label"',
            );
          }
        }
      },
    );

    test('preserva aliases manuais históricos', () {
      expect(CategoryNormalizer.normalizeRoleId('produtor'), 'produtor');
      expect(
        CategoryNormalizer.normalizeRoleId('Diretor Musical'),
        'diretor_musical',
      );
      expect(
        CategoryNormalizer.normalizeRoleId('Backline Tech'),
        'backline_tech',
      );

      expect(CategoryNormalizer.isProductionRoleId('produtor'), isTrue);
      expect(CategoryNormalizer.isProductionRoleId('diretor_musical'), isTrue);
      expect(CategoryNormalizer.isStageTechRoleId('backline_tech'), isTrue);
    });

    test('inputs desconhecidos voltam sanitizados sem modificação', () {
      expect(
        CategoryNormalizer.normalizeRoleId('Funcao Customizada'),
        'funcao_customizada',
      );
      expect(
        CategoryNormalizer.isProductionRoleId('funcao_customizada'),
        isFalse,
      );
      expect(
        CategoryNormalizer.isStageTechRoleId('funcao_customizada'),
        isFalse,
      );
    });
  });

  group('professionalRoleAliasLookup — sanity check', () {
    test('cobre todas as listas legadas de roles em app_constants', () {
      final expected = {
        for (final label in app_constants.productionRoles)
          CategoryNormalizer.sanitize(label),
        for (final label in app_constants.stageTechRoles)
          CategoryNormalizer.sanitize(label),
        for (final label in app_constants.audiovisualRoles)
          CategoryNormalizer.sanitize(label),
        for (final label in app_constants.educationRoles)
          CategoryNormalizer.sanitize(label),
        for (final label in app_constants.luthierRoles)
          CategoryNormalizer.sanitize(label),
        for (final label in app_constants.performanceRoles)
          CategoryNormalizer.sanitize(label),
        'produtor',
        'diretor_musical',
        'backline_tech',
      };
      expect(professionalRoleAliasLookup.keys.toSet(), containsAll(expected));
    });
  });
}
