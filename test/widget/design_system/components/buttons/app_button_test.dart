import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/buttons/app_button.dart';

void main() {
  group('AppButton', () {
    group('Primary Variant', () {
      testWidgets('renders with text', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton.primary(text: 'Primary Action', onPressed: () {}),
            ),
          ),
        );

        expect(find.text('Primary Action'), findsOneWidget);
      });

      testWidgets('triggers onPressed when tapped', (
        WidgetTester tester,
      ) async {
        bool pressed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton.primary(
                text: 'Click Me',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AppButton));
        await tester.pump();

        expect(pressed, isTrue);
      });

      testWidgets('shows loading indicator when isLoading is true', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton.primary(
                text: 'Loading...',
                onPressed: () {},
                isLoading: true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('does not trigger onPressed when isLoading is true', (
        WidgetTester tester,
      ) async {
        bool pressed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton.primary(
                text: 'Click Me',
                onPressed: () => pressed = true,
                isLoading: true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AppButton));
        await tester.pump();

        expect(pressed, isFalse);
      });
    });

    group('Secondary Variant', () {
      testWidgets('renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton.secondary(
                text: 'Secondary Action',
                onPressed: () {},
              ),
            ),
          ),
        );
        expect(find.text('Secondary Action'), findsOneWidget);
      });
    });

    group('Outline Variant', () {
      testWidgets('renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton.outline(text: 'Outline Action', onPressed: () {}),
            ),
          ),
        );
        expect(find.text('Outline Action'), findsOneWidget);
      });
    });
  });
}
