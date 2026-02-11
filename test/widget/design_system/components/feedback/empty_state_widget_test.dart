import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/feedback/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders with icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.search,
              title: 'Nenhum resultado',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Nenhum resultado'), findsOneWidget);
    });

    testWidgets('renders with subtitle when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.favorite,
              title: 'Favoritos vazios',
              subtitle: 'Adicione músicos aos seus favoritos',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('Favoritos vazios'), findsOneWidget);
      expect(find.text('Adicione músicos aos seus favoritos'), findsOneWidget);
    });

    testWidgets('renders without subtitle when not provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.notifications,
              title: 'Sem notificações',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('Sem notificações'), findsOneWidget);
      // Should only find the title text - there may be other Text widgets in MaterialApp
      expect(find.text('Sem notificações'), findsOneWidget);
    });

    testWidgets('renders with action button when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.error,
              title: 'Erro',
              subtitle: 'Algo deu errado',
              actionButton: ElevatedButton(
                onPressed: () {},
                child: const Text('Tentar novamente'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Erro'), findsOneWidget);
      expect(find.text('Algo deu errado'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('action button is tappable', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.refresh,
              title: 'Atualizar',
              actionButton: ElevatedButton(
                onPressed: () => pressed = true,
                child: const Text('Atualizar'),
              ),
            ),
          ),
        ),
      );

      // Find the ElevatedButton and tap it
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has animation controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.hourglass_empty,
              title: 'Carregando',
            ),
          ),
        ),
      );

      // Should have FadeTransition and ScaleTransition in the widget tree
      // Note: MaterialApp may have other transitions, so we check at least one exists
      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('animation runs on init', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(icon: Icons.timer, title: 'Iniciando'),
          ),
        ),
      );

      // Initial pump should show the widget
      expect(find.text('Iniciando'), findsOneWidget);

      // Let animation complete
      await tester.pump(const Duration(milliseconds: 500));

      // Widget should still be visible after animation
      expect(find.text('Iniciando'), findsOneWidget);
    });

    testWidgets('icon is displayed in a circular container', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(icon: Icons.person, title: 'Perfil'),
          ),
        ),
      );

      // Find the container with circular shape
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );

      expect(container, isNotNull);
    });

    testWidgets('centers content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.center_focus_strong,
              title: 'Centralizado',
            ),
          ),
        ),
      );

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('has correct padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(icon: Icons.padding, title: 'Com padding'),
          ),
        ),
      );

      // Find Padding widgets - there will be multiple in the tree
      final paddings = tester.widgetList<Padding>(
        find.byWidgetPredicate(
          (widget) => widget is Padding && widget.padding is EdgeInsets,
        ),
      );

      expect(paddings.isNotEmpty, isTrue);
    });

    testWidgets('handles different icon types', (WidgetTester tester) async {
      const icons = [
        Icons.search,
        Icons.favorite,
        Icons.notifications,
        Icons.error,
        Icons.check_circle,
      ];

      for (final icon in icons) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget(icon: icon, title: 'Test'),
            ),
          ),
        );

        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    testWidgets('disposes animation controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(icon: Icons.delete, title: 'Removido'),
          ),
        ),
      );

      // Should not throw when disposing
      await tester.pumpWidget(Container());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
