import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/common_widgets/primary_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('renders text correctly', (tester) async {
      await tester.pumpApp(const PrimaryButton(text: 'Test Button'));

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpApp(
        PrimaryButton(text: 'Press Me', onPressed: () => pressed = true),
      );

      await tester.tap(find.text('Press Me'));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('does not call onPressed when isLoading is true', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpApp(
        PrimaryButton(
          text: 'Loading',
          isLoading: true,
          onPressed: () => pressed = true,
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, false);
    });

    testWidgets('shows CircularProgressIndicator when isLoading', (
      tester,
    ) async {
      await tester.pumpApp(
        const PrimaryButton(text: 'Loading', isLoading: true),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('shows text when not loading', (tester) async {
      await tester.pumpApp(
        const PrimaryButton(text: 'Not Loading', isLoading: false),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Not Loading'), findsOneWidget);
    });

    testWidgets('has correct height of 56', (tester) async {
      await tester.pumpApp(const PrimaryButton(text: 'Height Test'));

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(ElevatedButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.height, 56);
    });

    testWidgets('button is disabled when onPressed is null', (tester) async {
      await tester.pumpApp(
        const PrimaryButton(text: 'Disabled', onPressed: null),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
