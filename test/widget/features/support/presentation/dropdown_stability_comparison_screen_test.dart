import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/support/presentation/dropdown_stability_comparison_screen.dart';

void main() {
  Widget createSubject() {
    return const MaterialApp(home: DropdownStabilityComparisonScreen());
  }

  group('DropdownStabilityComparisonScreen', () {
    testWidgets('renders initial state with dropdown mode', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Comparativo de Dropdown'), findsOneWidget);
      expect(
        find.textContaining('Modo ativo: Dropdown com Overlay'),
        findsOneWidget,
      );
      expect(find.text('Categoria'), findsOneWidget);
      expect(find.text('Simular Envio'), findsOneWidget);
    });

    testWidgets('switches to modal mode', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alternativa'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Modo ativo: Modal Bottom Sheet'),
        findsOneWidget,
      );
    });
  });
}
