import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_remote_data_source.dart';

class _FakeFunctions extends Fake implements FirebaseFunctions {}

Map<String, dynamic> _userDoc({
  required String uid,
  required String email,
  Map<String, dynamic>? matchpointProfile,
  Map<String, dynamic>? profissional,
  Map<String, dynamic>? banda,
}) {
  final doc = <String, dynamic>{
    'uid': uid,
    'email': email,
  };

  if (matchpointProfile != null) {
    doc['matchpoint_profile'] = matchpointProfile;
  }
  if (profissional != null) {
    doc['profissional'] = profissional;
  }
  if (banda != null) {
    doc['banda'] = banda;
  }

  return doc;
}

void main() {
  group('MatchpointRemoteDataSource.fetchCandidates', () {
    test(
      'fallback finds candidate when genres are stored in legacy matchpoint key',
      () async {
        final firestore = FakeFirebaseFirestore();
        final dataSource = MatchpointRemoteDataSourceImpl(
          firestore,
          _FakeFunctions(),
        );

        await firestore
            .collection('users')
            .doc('current')
            .set(_userDoc(uid: 'current', email: 'current@test.com'));
        await firestore
            .collection('users')
            .doc('candidate')
            .set(
              _userDoc(
                uid: 'candidate',
                email: 'candidate@test.com',
                matchpointProfile: {
                  'is_active': true,
                  'musicalGenres': ['rock'], // Legacy camelCase key
                },
              ),
            );

        final result = await dataSource.fetchCandidates(
          currentUserId: 'current',
          genres: ['rock'],
          excludedUserIds: const [],
        );

        expect(result, hasLength(1));
        expect(result.first.uid, 'candidate');
      },
    );

    test(
      'fallback handles case mismatch between query genres and stored genres',
      () async {
        final firestore = FakeFirebaseFirestore();
        final dataSource = MatchpointRemoteDataSourceImpl(
          firestore,
          _FakeFunctions(),
        );

        await firestore
            .collection('users')
            .doc('current')
            .set(_userDoc(uid: 'current', email: 'current@test.com'));
        await firestore
            .collection('users')
            .doc('candidate')
            .set(
              _userDoc(
                uid: 'candidate',
                email: 'candidate@test.com',
                matchpointProfile: {
                  'is_active': true,
                  'generosMusicais': ['rock'],
                },
              ),
            );

        final result = await dataSource.fetchCandidates(
          currentUserId: 'current',
          genres: ['Rock'],
          excludedUserIds: const [],
        );

        expect(result, hasLength(1));
        expect(result.first.uid, 'candidate');
      },
    );
  });
}
