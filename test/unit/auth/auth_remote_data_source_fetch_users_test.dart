import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';

import '../../helpers/firebase_mocks.dart';

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

class _FakeAppCheck extends Fake implements app_check.FirebaseAppCheck {
  @override
  Future<String?> getToken([bool? forceRefresh]) async => 'app-check-token';
}

void main() {
  group('AuthRemoteDataSourceImpl.fetchUsersByIds', () {
    late FakeFirebaseFirestore firestore;
    late AuthRemoteDataSourceImpl dataSource;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      dataSource = AuthRemoteDataSourceImpl(
        MockFirebaseAuth(),
        firestore,
        functions: _FakeFirebaseFunctions(),
        publicUsernameFunctions: _FakeFirebaseFunctions(),
        appCheck: _FakeAppCheck(),
      );
    });

    test(
      'loads users across Firestore whereIn chunks and preserves request order',
      () async {
        for (var index = 0; index < 35; index++) {
          final uid = 'user-$index';
          await firestore.collection(FirestoreCollections.users).doc(uid).set({
            'uid': uid,
            'email': '$uid@example.com',
            'cadastro_status': 'concluido',
          });
        }

        final requestedIds = <String>[
          ...List.generate(5, (index) => 'user-${34 - index}'),
          ...List.generate(30, (index) => 'user-$index'),
        ];

        final users = await dataSource.fetchUsersByIds(requestedIds);

        expect(users, hasLength(requestedIds.length));
        expect(users.map((user) => user.uid).toList(), requestedIds);
        expect(
          users.map((user) => user.email).toList(),
          requestedIds.map((uid) => '$uid@example.com').toList(),
        );
      },
    );
  });
}
