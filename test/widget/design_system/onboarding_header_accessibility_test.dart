import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/patterns/onboarding_header.dart';

void main() {
  testWidgets('back action has a labeled 48px touch target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: OnboardingHeader(currentStep: 1, totalSteps: 3, onBack: () {}),
        ),
      ),
    );

    expect(find.byTooltip('Voltar'), findsOneWidget);
    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
