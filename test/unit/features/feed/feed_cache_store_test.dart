import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/feed/data/feed_cache_store.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/feed_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('persists and restores a feed cache snapshot', () async {
    final store = FeedCacheStore(SharedPreferences.getInstance);
    final cachedAt = DateTime(2026, 4, 10, 12);

    await store.save(
      'user-1',
      FeedCacheSnapshot(
        cachedAt: cachedAt,
        currentFilter: 'Bandas',
        items: const [
          FeedItem(
            uid: 'band-1',
            nome: 'Banda Saturno',
            tipoPerfil: 'banda',
            distanceKm: 3.5,
            likeCount: 7,
          ),
        ],
        featuredItems: const [
          FeedItem(
            uid: 'featured-1',
            nome: 'Studio Aurora',
            tipoPerfil: 'estudio',
          ),
        ],
        sectionItems: const {
          FeedSectionType.bands: [
            FeedItem(uid: 'band-2', nome: 'Banda Lunar', tipoPerfil: 'banda'),
          ],
        },
      ),
    );

    final snapshot = await store.load('user-1');

    expect(snapshot, isNotNull);
    expect(snapshot!.cachedAt, cachedAt);
    expect(snapshot.currentFilter, 'Bandas');
    expect(snapshot.items.single.uid, 'band-1');
    expect(snapshot.items.single.likeCount, 7);
    expect(snapshot.items.single.distanceKm, 3.5);
    expect(snapshot.featuredItems.single.uid, 'featured-1');
    expect(snapshot.sectionItems[FeedSectionType.bands]?.single.uid, 'band-2');
  });
}
