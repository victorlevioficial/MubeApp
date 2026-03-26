import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/foundations/tokens/app_colors.dart';
import 'package:mube/src/design_system/components/data_display/user_avatar.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_card_compact.dart';

void main() {
  group('FeedCardCompact', () {
    const testItem = FeedItem(
      uid: 'user-1',
      nome: 'João Silva',
      nomeArtistico: 'João Rock',
      tipoPerfil: 'profissional',
      foto: 'https://example.com/photo.jpg',
      generosMusicais: ['rock', 'pop'],
      location: {'lat': -23.5, 'lng': -46.6},
      distanceKm: 5.0,
    );

    testWidgets('renders with artist name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: testItem, onTap: () {}),
          ),
        ),
      );

      expect(find.text('João Rock'), findsOneWidget);
    });

    testWidgets('renders contractor name when artistic name is null', (
      WidgetTester tester,
    ) async {
      const itemWithoutArtisticName = FeedItem(
        uid: 'user-2',
        nome: 'Maria Santos',
        tipoPerfil: 'contratante',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: itemWithoutArtisticName, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Maria Santos'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: testItem, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.text('João Rock'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders distance when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: testItem, onTap: () {}),
          ),
        ),
      );

      // The distance text should be rendered
      expect(find.text('5 km'), findsOneWidget);
    });

    testWidgets('renders profile type icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: testItem, onTap: () {}),
          ),
        ),
      );

      // Professional profile shows music_note icon
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('renders storefront icon for contractor type', (
      WidgetTester tester,
    ) async {
      const contractorItem = FeedItem(
        uid: 'venue-1',
        nome: 'Arena Azul',
        tipoPerfil: 'contratante',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: contractorItem, onTap: () {}),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.storefront_rounded));
      expect(icon.color, AppColors.warning);
    });

    testWidgets('renders band icon for band type', (WidgetTester tester) async {
      const bandItem = FeedItem(
        uid: 'band-1',
        nome: 'Banda Teste',
        tipoPerfil: 'banda',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: bandItem, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.groups), findsOneWidget);
    });

    testWidgets('renders studio icon for studio type', (
      WidgetTester tester,
    ) async {
      const studioItem = FeedItem(
        uid: 'studio-1',
        nome: 'Studio Teste',
        tipoPerfil: 'estudio',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: studioItem, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.headphones), findsOneWidget);
    });

    testWidgets('renders UserAvatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: testItem, onTap: () {}),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('has fixed width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: testItem, onTap: () {}),
          ),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == 110,
        ),
      );

      expect(sizedBoxes.isNotEmpty, isTrue);
    });

    testWidgets('name is centered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: testItem, onTap: () {}),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('João Rock'));
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('handles long names with ellipsis', (
      WidgetTester tester,
    ) async {
      const itemWithLongName = FeedItem(
        uid: 'user-3',
        nome: 'Nome Muito Longo Que Deveria Ser Truncado',
        nomeArtistico: 'Nome Muito Longo Que Deveria Ser Truncado',
        tipoPerfil: 'contratante',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: itemWithLongName, onTap: () {}),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(
        find.text('Nome Muito Longo Que Deveria Ser Truncado'),
      );
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 1);
    });

    testWidgets('does not show distance when not available', (
      WidgetTester tester,
    ) async {
      const itemWithoutLocation = FeedItem(
        uid: 'user-4',
        nome: 'Sem Localização',
        tipoPerfil: 'profissional',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCardCompact(item: itemWithoutLocation, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('does not overflow inside compact section height', (
      WidgetTester tester,
    ) async {
      FlutterErrorDetails? flutterError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        flutterError = details;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 110,
                height: 160,
                child: FeedCardCompact(item: testItem, onTap: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;
      expect(flutterError, isNull);
    });
  });
}
