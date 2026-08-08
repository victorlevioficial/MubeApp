import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/buttons/app_button.dart';

void main() {
  for (final size in AppButtonSize.values) {
    testWidgets('$size keeps a minimum 44px touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: AppButton.primary(
              text: 'Continuar',
              size: size,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AppButton)).height,
        greaterThanOrEqualTo(44),
      );
    });
  }
}
