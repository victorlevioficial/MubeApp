import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/inputs/app_dropdown_field.dart';

void main() {
  group('AppDropdownField', () {
    testWidgets('renders label and hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDropdownField<String>(
              label: 'Categoria',
              hint: 'Selecione',
              value: null,
              items: const [
                DropdownMenuItem(value: 'bug', child: Text('Problema')),
                DropdownMenuItem(value: 'feedback', child: Text('Feedback')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Categoria'), findsWidgets);
      expect(find.text('Selecione'), findsOneWidget);
    });

    testWidgets('updates selection through onChanged', (tester) async {
      String? selectedValue = 'feedback';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppDropdownField<String>(
                  label: 'Categoria',
                  value: selectedValue,
                  items: const [
                    DropdownMenuItem(value: 'bug', child: Text('Problema')),
                    DropdownMenuItem(
                      value: 'feedback',
                      child: Text('Feedback'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => selectedValue = value);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownMenuFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Problema').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'bug');
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, 'Problema');
    });

    testWidgets('does not fallback invalid value to first option', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDropdownField<String>(
              label: 'Gênero',
              hint: 'Selecione',
              value: 'valor-invalido',
              items: const [
                DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Selecione'), findsOneWidget);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, isEmpty);
    });
  });
}
