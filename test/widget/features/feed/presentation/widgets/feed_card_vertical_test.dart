import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/design_system/components/buttons/app_like_button.dart';
import 'package:mube/src/design_system/components/data_display/user_avatar.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_card_vertical.dart';
import 'package:mube/src/features/feed/presentation/widgets/profile_type_badge.dart';

void main() {
  group('FeedCardVertical', () {
    final testItem = FeedItem(
      uid: 'user-1',
      nome: 'João Silva',
      nomeArtistico: 'João Rock',
      tipoPerfil: 'profissional',
      foto: 'https://example.com/photo.jpg',
      generosMusicais: ['rock', 'pop'],
      skills: ['Guitarra', 'Vocal'],
      subCategories: ['singer', 'instrumentalist'],
      location: {'lat': -23.5, 'lng': -46.6},
      likeCount: 42,
      distanceKm: 5.0,
    );

    testWidgets('renders with artist name', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: testItem, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.text('João Rock'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(
                item: testItem,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FeedCardVertical));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders distance when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: testItem, onTap: () {}),
            ),
          ),
        ),
      );

      // The distance text should be rendered
      expect(find.text('5 km'), findsOneWidget);
    });

    testWidgets('renders profile type badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: testItem, onTap: () {}),
            ),
          ),
        ),
      );

      // Should find the ProfileTypeBadge widget
      expect(find.byType(ProfileTypeBadge), findsOneWidget);
    });

    testWidgets('renders skills chips when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: testItem, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.text('Guitarra'), findsOneWidget);
      expect(find.text('Vocal'), findsOneWidget);
    });

    testWidgets('renders genres chips when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: testItem, onTap: () {}),
            ),
          ),
        ),
      );

      // Genres are formatted (Rock, Pop from rock, pop)
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Pop'), findsOneWidget);
    });

    testWidgets('renders UserAvatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: testItem, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('renders AppLikeButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: testItem, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.byType(AppLikeButton), findsOneWidget);
    });

    testWidgets('has Hero widget for avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: testItem, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('applies scale animation on press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: testItem, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedScale), findsOneWidget);
    });

    testWidgets('renders without distance when not available', (
      WidgetTester tester,
    ) async {
      final itemWithoutLocation = FeedItem(
        uid: 'user-2',
        nome: 'Sem Localização',
        tipoPerfil: 'profissional',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: itemWithoutLocation, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('renders without skills when empty', (
      WidgetTester tester,
    ) async {
      final itemWithoutSkills = FeedItem(
        uid: 'user-3',
        nome: 'Sem Skills',
        tipoPerfil: 'profissional',
        skills: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: itemWithoutSkills, onTap: () {}),
            ),
          ),
        ),
      );

      // Should not render skills section
      expect(find.text('Guitarra'), findsNothing);
    });

    testWidgets('handles long names with ellipsis', (
      WidgetTester tester,
    ) async {
      final itemWithLongName = FeedItem(
        uid: 'user-4',
        nome: 'Nome Muito Longo Que Deveria Ser Truncado',
        tipoPerfil: 'profissional',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(item: itemWithLongName, onTap: () {}),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(
        find.text('Nome Muito Longo Que Deveria Ser Truncado'),
      );
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 1);
    });

    testWidgets('applies custom margin when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedCardVertical(
                item: testItem,
                onTap: () {},
                margin: const EdgeInsets.all(20),
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container && widget.margin == const EdgeInsets.all(20),
        ),
      );

      expect(container.margin, const EdgeInsets.all(20));
    });
  });
}
