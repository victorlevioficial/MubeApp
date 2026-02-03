import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/inputs/app_text_field.dart';

void main() {
  group('AppTextField', () {
    testWidgets('renders with label and hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(label: 'Username', hint: 'Enter your username'),
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Enter your username'), findsOneWidget);
    });

    testWidgets('updates controller text on input', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(label: 'Input', controller: controller),
          ),
        ),
      );

      await tester.enterText(find.byType(AppTextField), 'Hello World');
      await tester.pump();
      expect(controller.text, 'Hello World');
    });

    testWidgets('shows error text when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(label: 'Input', errorText: 'Invalid input'),
          ),
        ),
      );

      expect(find.text('Invalid input'), findsOneWidget);
    });
  });
}
