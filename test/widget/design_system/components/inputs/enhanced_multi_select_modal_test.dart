import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/inputs/enhanced_multi_select_modal.dart';

void main() {
  group('EnhancedMultiSelectModal', () {
    Widget buildTestWidget({
      required List<String> items,
      List<String> selectedItems = const [],
      String title = 'Instrumentos',
      String? subtitle = 'Selecione seus instrumentos',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: EnhancedMultiSelectModal<String>(
            title: title,
            subtitle: subtitle,
            items: items,
            selectedItems: selectedItems,
            itemLabel: (item) => item,
          ),
        ),
      );
    }

    testWidgets('renders title subtitle and search field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(items: const ['Guitarra', 'Bateria', 'Voz']),
      );

      expect(find.text('Instrumentos'), findsOneWidget);
      expect(find.text('Selecione seus instrumentos'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
    });

    testWidgets('updates selection count when item is toggled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          items: const ['Guitarra', 'Bateria', 'Voz'],
          selectedItems: const ['Guitarra'],
        ),
      );

      expect(find.text('1 selecionado'), findsOneWidget);
      expect(find.text('Confirmar (1)'), findsOneWidget);

      await tester.tap(find.text('Bateria'));
      await tester.pumpAndSettle();

      expect(find.text('2 selecionados'), findsOneWidget);
      expect(find.text('Confirmar (2)'), findsOneWidget);
    });

    testWidgets('shows empty search state when no items match query', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(items: const ['Rock', 'Jazz', 'Blues']),
      );

      await tester.enterText(find.byType(TextFormField), 'Metal');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
      expect(
        find.text('Tente outro termo para encontrar a opcao desejada.'),
        findsOneWidget,
      );
    });
  });
}
