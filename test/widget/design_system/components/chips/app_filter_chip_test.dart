import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/chips/app_filter_chip.dart';

void main() {
  group('AppFilterChip', () {
    testWidgets('renders with label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Filtro',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Filtro'), findsOneWidget);
    });

    testWidgets('renders unselected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Não selecionado',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Não selecionado'), findsOneWidget);
    });

    testWidgets('renders selected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Selecionado',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Selecionado'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Toque aqui',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Toque aqui'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('triggers onSelected with inverted value when tapped', (
      WidgetTester tester,
    ) async {
      bool? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Toggle',
              isSelected: false,
              onSelected: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(selectedValue, isTrue);
    });

    testWidgets('onSelected receives false when currently selected', (
      WidgetTester tester,
    ) async {
      bool? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Toggle',
              isSelected: true,
              onSelected: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(selectedValue, isFalse);
    });

    testWidgets('renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Com ícone',
              isSelected: false,
              icon: Icons.filter_list,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Com ícone'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('renders with remove button when onRemove is provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Removível',
              isSelected: false,
              onTap: () {},
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.text('Removível'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('triggers onRemove when close icon is tapped', (
      WidgetTester tester,
    ) async {
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Removível',
              isSelected: false,
              onTap: () {},
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(removed, isTrue);
    });

    testWidgets('both onTap and onSelected can be called', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      bool? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Ambos',
              isSelected: false,
              onTap: () => tapped = true,
              onSelected: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ambos'));
      await tester.pump();

      expect(tapped, isTrue);
      expect(selectedValue, isTrue);
    });

    testWidgets('renders without callbacks (static)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppFilterChip(label: 'Estático', isSelected: false),
          ),
        ),
      );

      expect(find.text('Estático'), findsOneWidget);
    });

    testWidgets('has correct tappable area', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterChip(
              label: 'Tappable',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should find the GestureDetector from the underlying AppChip
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
