import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/chips/app_chip.dart';

void main() {
  group('AppChip', () {
    group('Skill Variant', () {
      testWidgets('renders skill chip with label', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AppChip.skill(label: 'Guitarra')),
          ),
        );

        expect(find.text('Guitarra'), findsOneWidget);
      });

      testWidgets('skill chip has correct styling', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AppChip.skill(label: 'Guitarra')),
          ),
        );

        final container = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
      });
    });

    group('Genre Variant', () {
      testWidgets('renders genre chip with label', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AppChip.genre(label: 'Rock')),
          ),
        );

        expect(find.text('Rock'), findsOneWidget);
      });

      testWidgets('genre chip has correct styling', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AppChip.genre(label: 'Rock')),
          ),
        );

        final container = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
      });
    });

    group('Filter Variant', () {
      testWidgets('renders filter chip unselected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppChip.filter(
                label: 'Perto de mim',
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Perto de mim'), findsOneWidget);
      });

      testWidgets('renders filter chip selected', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppChip.filter(
                label: 'Selecionado',
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Selecionado'), findsOneWidget);
      });

      testWidgets('filter chip triggers onTap when tapped', (
        WidgetTester tester,
      ) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppChip.filter(
                label: 'Tap me',
                isSelected: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tap me'));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('filter chip with icon renders correctly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppChip.filter(
                label: 'Com ícone',
                isSelected: false,
                icon: Icons.location_on,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Com ícone'), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsOneWidget);
      });

      testWidgets('filter chip with delete callback shows close icon', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppChip.filter(
                label: 'Removível',
                isSelected: false,
                onTap: () {},
                onDeleted: () {},
              ),
            ),
          ),
        );

        expect(find.text('Removível'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('delete callback is triggered when close icon tapped', (
        WidgetTester tester,
      ) async {
        bool deleted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppChip.filter(
                label: 'Removível',
                isSelected: false,
                onTap: () {},
                onDeleted: () => deleted = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(deleted, isTrue);
      });

      testWidgets('filter chip animates on selection change', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppChip.filter(
                label: 'Animado',
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.byType(AnimatedContainer), findsOneWidget);
      });
    });

    group('Default Constructor', () {
      testWidgets('renders with default skill variant', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AppChip(label: 'Default')),
          ),
        );

        expect(find.text('Default'), findsOneWidget);
      });

      testWidgets('renders skill variant explicitly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppChip(label: 'Skill', variant: AppChipVariant.skill),
            ),
          ),
        );

        expect(find.text('Skill'), findsOneWidget);
      });

      testWidgets('renders genre variant explicitly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppChip(label: 'Genre', variant: AppChipVariant.genre),
            ),
          ),
        );

        expect(find.text('Genre'), findsOneWidget);
      });

      testWidgets('renders filter variant explicitly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppChip(
                label: 'Filter',
                variant: AppChipVariant.filter,
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Filter'), findsOneWidget);
      });
    });

    group('Semantics', () {
      testWidgets('filter chip with onTap is tappable', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppChip.filter(
                label: 'Tappable',
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        final gestureDetector = tester.widget<GestureDetector>(
          find.byType(GestureDetector),
        );
        expect(gestureDetector.onTap, isNotNull);
      });
    });
  });
}
