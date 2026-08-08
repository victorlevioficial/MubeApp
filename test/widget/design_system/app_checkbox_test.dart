import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/inputs/app_checkbox.dart';

void main() {
  testWidgets('exposes one semantic checkbox with a full touch target', (
    tester,
  ) async {
    final changes = <bool?>[];
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AppCheckbox(
            label: 'Tenho 18 anos ou mais',
            value: false,
            onChanged: changes.add,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(AppCheckbox)).height,
      greaterThanOrEqualTo(48),
    );
    final node = tester.getSemantics(find.byType(AppCheckbox));
    expect(node.label, 'Tenho 18 anos ou mais');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.flagsCollection.isChecked, CheckedState.isFalse);

    await tester.tap(find.text('Tenho 18 anos ou mais'));
    await tester.pump();

    expect(changes, [true]);
    semantics.dispose();
  });
}
