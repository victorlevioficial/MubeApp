import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/shared/widgets/dismiss_keyboard_on_tap.dart';

void main() {
  group('DismissKeyboardOnTap', () {
    testWidgets(
      'keeps focus when tapping interactive controls outside the field',
      (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DismissKeyboardOnTap(
                child: Column(
                  children: [
                    TextField(focusNode: focusNode),
                    TextButton(onPressed: () {}, child: const Text('Enviar')),
                    const Expanded(child: SizedBox.expand()),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(TextField));
        await tester.pump();
        expect(focusNode.hasFocus, isTrue);

        await tester.tap(find.text('Enviar'));
        await tester.pump();
        expect(focusNode.hasFocus, isTrue);
      },
    );

    testWidgets('dismisses focus when tapping empty space', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DismissKeyboardOnTap(
              child: Column(
                children: [
                  TextField(focusNode: focusNode),
                  const Expanded(child: SizedBox.expand()),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tapAt(const Offset(200, 500));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });
  });
}
