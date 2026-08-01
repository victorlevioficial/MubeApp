import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/feed/data/featured_profiles_repository.dart';

void main() {
  group('FeaturedProfilesRepository', () {
    test('returns empty only when featured configuration is absent', () async {
      final repository = FeaturedProfilesRepository(FakeFirebaseFirestore());

      await expectLater(repository.getFeaturedUids(), completion(isEmpty));
    });

    test(
      'does not turn malformed featured configuration into an empty list',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('config').doc('featuredProfiles').set({
          'uids': ['valid-user', 42],
        });
        final repository = FeaturedProfilesRepository(firestore);

        await expectLater(repository.getFeaturedUids(), throwsA(anything));
      },
    );
  });
}
