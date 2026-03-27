import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/domain/app_config.dart';
import 'package:mube/src/core/providers/app_config_provider.dart';
import 'package:mube/src/features/search/domain/search_filters.dart';
import 'package:mube/src/features/search/presentation/widgets/filter_modal.dart';

void main() {
  const appConfig = AppConfig(
    productionRoles: [
      ConfigItem(id: 'diretor_musical', label: 'Diretor Musical'),
    ],
    stageTechRoles: [ConfigItem(id: 'backline_tech', label: 'Backline Tech')],
    audiovisualRoles: [ConfigItem(id: 'videomaker', label: 'Videomaker')],
    educationRoles: [ConfigItem(id: 'professor', label: 'Professor(a)')],
    luthierRoles: [ConfigItem(id: 'setup', label: 'Ajuste e Regulagem')],
    performanceRoles: [ConfigItem(id: 'performer', label: 'Performer')],
  );

  Widget createSubject(SearchFilters filters) {
    return ProviderScope(
      overrides: [appConfigProvider.overrideWith((ref) async => appConfig)],
      child: MaterialApp(
        home: Scaffold(
          body: FilterModal(filters: filters, onApply: (_) {}),
        ),
      ),
    );
  }

  Finder scrollable() => find.byType(Scrollable);

  Finder textContaining(String snippet) =>
      find.textContaining(snippet, findRichText: true, skipOffstage: false);

  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.dragUntilVisible(
      textContaining('Backing vocal'),
      scrollable(),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
  }

  group('FilterModal', () {
    testWidgets(
      'shows production roles and remote recording section for production',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            const SearchFilters(
              category: SearchCategory.professionals,
              professionalSubcategory: ProfessionalSubcategory.production,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await scrollToBottom(tester);

        expect(textContaining('Gravação remota'), findsOneWidget);
        expect(textContaining('Somente com gravação remota'), findsOneWidget);
      },
    );

    testWidgets(
      'shows stage tech roles without remote recording section for stage tech',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            const SearchFilters(
              category: SearchCategory.professionals,
              professionalSubcategory: ProfessionalSubcategory.stageTech,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await scrollToBottom(tester);

        expect(textContaining('remota'), findsNothing);
      },
    );

    testWidgets('shows the new professional subcategory chips', (tester) async {
      await tester.pumpWidget(
        createSubject(
          const SearchFilters(category: SearchCategory.professionals),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Audiovisual'), findsOneWidget);
      expect(find.text('Educacao Musical'), findsOneWidget);
      expect(find.text('Luthieria'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);
    });
  });
}
