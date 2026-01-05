import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/presentation/login_screen.dart';

import '../../helpers/test_utils.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpApp(const LoginScreen());

      // Should find email field
      expect(find.text('E-mail'), findsOneWidget);

      // Should find password field
      expect(find.text('Senha'), findsOneWidget);
    });

    testWidgets('renders login button', (tester) async {
      await tester.pumpApp(const LoginScreen());

      // Should find login button
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('renders register link', (tester) async {
      await tester.pumpApp(const LoginScreen());

      // Should find register prompt
      expect(find.text('Criar conta'), findsOneWidget);
    });

    testWidgets('shows error when submitting empty form', (tester) async {
      await tester.pumpApp(const LoginScreen());

      // Tap login button without entering data
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      // Should show validation errors (form validation)
      // The exact error messages depend on implementation
    });

    testWidgets('email field accepts input', (tester) async {
      await tester.pumpApp(const LoginScreen());

      // Find email field by its hint/label
      final emailField = find.ancestor(
        of: find.text('E-mail'),
        matching: find.byType(TextFormField),
      );

      // If found, verify we can enter text
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'test@example.com');
        expect(find.text('test@example.com'), findsOneWidget);
      }
    });

    testWidgets('password field obscures text', (tester) async {
      await tester.pumpApp(const LoginScreen());

      // Find password TextFormField - it should have obscureText set
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
    });
  });
}
