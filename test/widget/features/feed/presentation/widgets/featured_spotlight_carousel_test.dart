import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/widgets/featured_spotlight_carousel.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  List<FeedItem> buildItems(int count) {
    return List<FeedItem>.generate(
      count,
      (index) => FeedItem(
        uid: 'uid-$index',
        nome: 'Nome $index',
        nomeArtistico: 'Artista $index',
        foto: 'https://example.com/$index.jpg',
        tipoPerfil: 'profissional',
      ),
      growable: false,
    );
  }

  Future<void> pumpCarousel(
    WidgetTester tester, {
    required List<FeedItem> items,
    required void Function(FeedItem) onItemTap,
  }) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeaturedSpotlightCarousel(items: items, onItemTap: onItemTap),
        ),
      ),
    );
  }

  testWidgets('renders nothing when there are no items', (tester) async {
    await mockNetworkImagesFor(() async {
      await pumpCarousel(tester, items: const [], onItemTap: (_) {});
    });

    expect(find.byType(PageView), findsNothing);
    expect(find.text('Em Destaque'), findsNothing);
  });

  testWidgets('shows the header and one card per single item', (tester) async {
    FeedItem? tapped;

    await mockNetworkImagesFor(() async {
      await pumpCarousel(
        tester,
        items: buildItems(1),
        onItemTap: (item) => tapped = item,
      );
      // A single item must not schedule an auto-scroll timer. If one leaked,
      // the framework would fail this test with a pending-timer error.
      await tester.pump(const Duration(milliseconds: 300));
    });

    expect(find.text('Em Destaque'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    expect(tapped?.uid, 'uid-0');
  });

  testWidgets('does not auto-advance with a single item', (tester) async {
    FeedItem? tapped;

    await mockNetworkImagesFor(() async {
      await pumpCarousel(
        tester,
        items: buildItems(1),
        onItemTap: (item) => tapped = item,
      );
      await tester.pump(const Duration(seconds: 6));
    });

    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    expect(tapped?.uid, 'uid-0');
  });

  testWidgets('auto-advances forward to the next item after the interval', (
    tester,
  ) async {
    FeedItem? tapped;

    await mockNetworkImagesFor(() async {
      await pumpCarousel(
        tester,
        items: buildItems(3),
        onItemTap: (item) => tapped = item,
      );

      final center = tester.getCenter(find.byType(PageView));

      // The first card is centered initially.
      await tester.tapAt(center);
      expect(tapped?.uid, 'uid-0');

      // Let the auto-scroll timer fire and the slide animation complete.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 600));

      // It advanced forward to the second card (not rewound to the start).
      await tester.tapAt(center);
      expect(tapped?.uid, 'uid-1');

      // Dispose the carousel to cancel the pending periodic timer.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    });
  });

  testWidgets('pauses auto-scroll while the user is touching the carousel', (
    tester,
  ) async {
    FeedItem? tapped;

    await mockNetworkImagesFor(() async {
      await pumpCarousel(
        tester,
        items: buildItems(3),
        onItemTap: (item) => tapped = item,
      );

      final center = tester.getCenter(find.byType(PageView));

      // Hold a finger down on the carousel; the timer must be cancelled.
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await tester.pump();

      // Still on the first card because auto-scroll was paused while touched.
      await tester.tapAt(center);
      expect(tapped?.uid, 'uid-0');

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    });
  });
}
