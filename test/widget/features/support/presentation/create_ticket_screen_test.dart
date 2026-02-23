import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/inputs/app_dropdown_field.dart';
import 'package:mube/src/design_system/components/inputs/app_text_field.dart';
import 'package:mube/src/features/support/presentation/create_ticket_screen.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CreateTicketScreen())),
    );
    await tester.pumpAndSettle();
  }

  group('CreateTicketScreen', () {
    testWidgets('renders all form fields correctly', (tester) async {
      await pumpScreen(tester);

      // Verify header text
      expect(find.text('Como podemos ajudar?'), findsOneWidget);
      expect(
        find.text('Descreva seu problema ou sugestão abaixo.'),
        findsOneWidget,
      );

      // Verify form fields
      expect(find.byType(AppDropdownField<String>), findsOneWidget);
      // Title + Description
      expect(find.byType(AppTextField), findsWidgets);
      expect(find.text('Assunto'), findsOneWidget);
      expect(find.text('Descrição Detalhada'), findsOneWidget);

      // Verify submit button
      expect(find.text('Enviar Solicitação'), findsOneWidget);
    });

    testWidgets('shows default category as feedback', (tester) async {
      await pumpScreen(tester);

      // Default category should be 'feedback'
      expect(find.text('Sugestão ou Feedback'), findsOneWidget);
    });

    testWidgets('can change category', (tester) async {
      await pumpScreen(tester);

      // Tap dropdown
      await tester.tap(find.byType(AppDropdownField<String>));
      await tester.pumpAndSettle();

      // Select 'bug' category
      await tester.tap(find.text('Reportar um Problema').last);
      await tester.pumpAndSettle();

      // Verify selection
      expect(find.text('Reportar um Problema'), findsOneWidget);
    });

    testWidgets('validates empty title', (tester) async {
      await pumpScreen(tester);

      // Fill description only
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Descrição Detalhada'),
        'Descrição com mais de 10 caracteres',
      );

      // Try to submit
      await tester.tap(find.text('Enviar Solicitação'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Informe o assunto'), findsOneWidget);
    });

    testWidgets('validates short description (less than 10 chars)', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Fill title
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Assunto'),
        'Título do ticket',
      );

      // Fill short description
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Descrição Detalhada'),
        'Curto',
      );

      // Try to submit
      await tester.tap(find.text('Enviar Solicitação'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Descreva com mais detalhes'), findsOneWidget);
    });

    testWidgets('shows attachment counter (0/3)', (tester) async {
      await pumpScreen(tester);

      // Verify attachment counter
      expect(find.text('0/3'), findsOneWidget);
      expect(find.text('Anexos (Opcional)'), findsOneWidget);
    });

    testWidgets('shows add photo button', (tester) async {
      await pumpScreen(tester);

      // Verify add photo icon
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    });
  });
}
