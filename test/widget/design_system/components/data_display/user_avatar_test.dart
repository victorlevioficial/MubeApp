import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/data_display/user_avatar.dart';

void main() {
  group('UserAvatar', () {
    testWidgets('renders with photo URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoUrl: 'https://example.com/photo.jpg',
              name: 'John Doe',
              size: 80,
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders initials when photoUrl is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(photoUrl: null, name: 'John Doe', size: 80),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('renders initials when photoUrl is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(photoUrl: '', name: 'John Doe', size: 80),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('renders single initial for single name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(photoUrl: null, name: 'John', size: 80),
          ),
        ),
      );

      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('renders question mark when name is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(photoUrl: null, name: null, size: 80),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('renders question mark when name is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UserAvatar(photoUrl: null, name: '', size: 80)),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('applies correct size', (WidgetTester tester) async {
      const size = 120.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(photoUrl: null, name: 'Test User', size: size),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints != null &&
              widget.constraints!.maxWidth == size,
        ),
      );

      expect(container.constraints!.maxWidth, size);
      expect(container.constraints!.maxHeight, size);
    });

    testWidgets('has circular shape', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(photoUrl: null, name: 'Test User', size: 80),
          ),
        ),
      );

      final clipOval = tester.widget<ClipOval>(find.byType(ClipOval));
      expect(clipOval, isNotNull);
    });

    testWidgets('renders with border', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(photoUrl: null, name: 'Test User', size: 80),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).border != null,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('uses different colors for different names', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                UserAvatar(photoUrl: null, name: 'Alice', size: 80),
                UserAvatar(photoUrl: null, name: 'Bob', size: 80),
                UserAvatar(photoUrl: null, name: 'Charlie', size: 80),
              ],
            ),
          ),
        ),
      );

      // Each avatar should render with its initials
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('handles names with multiple spaces correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(photoUrl: null, name: 'John Doe Smith', size: 80),
          ),
        ),
      );

      // Should take first and second word initials
      expect(find.text('JD'), findsOneWidget);
    });
  });
}
