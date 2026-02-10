import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/support/presentation/support_screen.dart';

void main() {
  Widget createSubject() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SupportScreen(),
        ),
        GoRoute(
          path: '/settings/support/create-ticket',
          builder: (context, state) =>
              const Scaffold(body: Text('Create Ticket Screen')),
        ),
        GoRoute(
          path: '/settings/support/my-tickets',
          builder: (context, state) =>
              const Scaffold(body: Text('Tickets List Screen')),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('SupportScreen', () {
    testWidgets('renders correctly with app bar', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Ajuda e Suporte'), findsOneWidget);
    });

    testWidgets('renders intro card', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Central de Ajuda do Mube'), findsOneWidget);
    });

    testWidgets('renders action cards', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Novo Ticket'), findsOneWidget);
      expect(find.text('Meus Tickets'), findsOneWidget);
    });

    testWidgets('navigates to create ticket screen', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novo Ticket'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Create Ticket Screen'), findsOneWidget);
    });

    testWidgets('navigates to tickets list screen', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meus Tickets'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tickets List Screen'), findsOneWidget);
    });

    testWidgets('renders FAQ section', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Perguntas Frequentes'), findsOneWidget);
    });

    testWidgets('renders search field', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders category filters', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Todas'), findsOneWidget);
    });

    testWidgets('renders contact section', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Ainda precisa de atendimento humano?'), findsOneWidget);
    });
  });
}
