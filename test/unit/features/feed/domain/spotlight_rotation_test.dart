import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/spotlight_rotation.dart';

void main() {
  group('SpotlightRotation', () {
    test('rotates the spotlight window across the full pool over time', () {
      final pool = List<FeedItem>.generate(
        8,
        (index) => FeedItem(
          uid: 'item-$index',
          nome: 'Item $index',
          tipoPerfil: ProfileType.professional,
        ),
        growable: false,
      );

      final firstWindow = SpotlightRotation.build(
        priorityItems: const [],
        candidateItems: pool,
        now: DateTime.utc(2026, 1, 1, 0),
      );
      final secondWindow = SpotlightRotation.build(
        priorityItems: const [],
        candidateItems: pool,
        now: DateTime.utc(2026, 1, 1, 3),
      );
      final thirdWindow = SpotlightRotation.build(
        priorityItems: const [],
        candidateItems: pool,
        now: DateTime.utc(2026, 1, 1, 6),
      );

      expect(firstWindow.map((item) => item.uid), [
        'item-0',
        'item-1',
        'item-2',
        'item-3',
        'item-4',
      ]);
      expect(secondWindow.map((item) => item.uid), [
        'item-5',
        'item-6',
        'item-7',
        'item-0',
        'item-1',
      ]);
      expect(thirdWindow.map((item) => item.uid), [
        'item-2',
        'item-3',
        'item-4',
        'item-5',
        'item-6',
      ]);
    });

    test(
      'prioritizes admin items, removes duplicates, and skips contractors',
      () {
        final spotlight = SpotlightRotation.build(
          priorityItems: const [
            FeedItem(
              uid: 'contractor',
              nome: 'Contratante',
              tipoPerfil: 'contratante',
            ),
            FeedItem(uid: 'band', nome: 'Band', tipoPerfil: ProfileType.band),
            FeedItem(
              uid: 'pro',
              nome: 'Pro',
              tipoPerfil: ProfileType.professional,
            ),
          ],
          candidateItems: const [
            FeedItem(
              uid: 'pro',
              nome: 'Pro 2',
              tipoPerfil: ProfileType.professional,
            ),
            FeedItem(
              uid: 'studio',
              nome: 'Studio',
              tipoPerfil: ProfileType.studio,
            ),
            FeedItem(
              uid: 'artist',
              nome: 'Artist',
              tipoPerfil: ProfileType.professional,
            ),
          ],
          now: DateTime.utc(2026, 1, 1, 0),
          maxItems: 5,
        );

        expect(spotlight.map((item) => item.uid), [
          'band',
          'pro',
          'studio',
          'artist',
        ]);
        expect(
          spotlight.where((item) => item.tipoPerfil == ProfileType.contractor),
          isEmpty,
        );
      },
    );
  });
}
