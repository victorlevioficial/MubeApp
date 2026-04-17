import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/loading/app_loading_indicator.dart';

void main() {
  group('AppLoadingIndicator', () {
    testWidgets('exposes live region semantics with label and hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingIndicator(
              semanticLabel: 'Carregando perfis',
              semanticHint: 'Aguarde a atualizacao da lista',
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Carregando perfis'), findsOneWidget);
    });

    testWidgets('wraps overlay with loading semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingOverlay(
              isLoading: true,
              message: 'Carregando dados',
              child: Text('Conteudo'),
            ),
          ),
        ),
      );

      expect(find.text('Conteudo'), findsOneWidget);
      expect(find.bySemanticsLabel('Carregando dados'), findsWidgets);
    });
  });
}
