import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/interactions/app_animated_press.dart';

void main() {
  group('AppAnimatedPress', () {
    testWidgets('exposes semantics when label is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAnimatedPress(
              semanticLabel: 'Abrir perfil',
              semanticHint: 'Toque para abrir os detalhes',
              onPressed: () {},
              child: const SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Abrir perfil'), findsOneWidget);
    });

    testWidgets('keeps tap behavior when semantics are not provided', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAnimatedPress(
              onPressed: () => tapped = true,
              child: const SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppAnimatedPress));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
