import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/gigs/data/gig_search_index.dart';

void main() {
  group('gig search index', () {
    test('normalizes accents, punctuation and repeated whitespace', () {
      expect(
        normalizeGigSearchText('  São José / MÚSICA!  '),
        'sao jose musica',
      );
    });

    test('includes title, description and location label', () {
      expect(
        buildGigSearchText(
          title: 'Banda de baile',
          description: 'Show corporativo',
          location: const {'label': 'Niterói, RJ'},
        ),
        'banda de baile show corporativo niteroi rj',
      );
    });

    test('builds stable one, two and three character grams', () {
      final grams = buildGigSearchGrams(title: 'Sax', description: 'Jazz');

      expect(grams, containsAll(<String>['s', 'sa', 'sax', 'j', 'ja', 'jaz']));
      expect(grams.toSet().length, grams.length);
      expect(grams, orderedEquals([...grams]..sort()));
    });

    test('uses the first normalized trigram as the indexed lookup key', () {
      expect(gigSearchLookupGram('  São Paulo '), 'sao');
      expect(gigSearchLookupGram('DJ'), 'dj');
      expect(gigSearchLookupGram('!!!'), isEmpty);
    });

    test('caps indexed text to keep Firestore documents bounded', () {
      final text = buildGigSearchText(
        title: List.filled(3000, 'a').join(),
        description: 'description',
      );

      expect(text, hasLength(2500));
    });
  });
}
