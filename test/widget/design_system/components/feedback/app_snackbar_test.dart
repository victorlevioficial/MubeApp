import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/buttons/app_button.dart';
import 'package:mube/src/design_system/components/feedback/app_snackbar.dart';

void main() {
  group('AppSnackBar', () {
    testWidgets('shows success snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => AppButton.primary(
                text: 'Show Success',
                onPressed: () =>
                    AppSnackBar.success(context, 'Success Message'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump(); // Start animation
      await tester.pump(
        const Duration(milliseconds: 50),
      ); // Advance animation slightly

      expect(find.text('Success Message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('shows error snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => AppButton.primary(
                text: 'Show Error',
                onPressed: () => AppSnackBar.error(context, 'Error Message'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Error Message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
