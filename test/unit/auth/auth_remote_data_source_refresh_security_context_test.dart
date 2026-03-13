import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';

import '../../helpers/firebase_mocks.dart';

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

class _FakeAppCheck extends Fake implements app_check.FirebaseAppCheck {
  int cachedTokenCalls = 0;

  @override
  Future<String?> getToken([bool? forceRefresh]) async {
    cachedTokenCalls += 1;
    return 'cached-app-check-token';
  }
}

class _TestUser extends Fake implements User {
  _TestUser({
    required this.uid,
    required Future<String?> Function(bool forceRefresh) onGetIdToken,
  }) : _onGetIdToken = onGetIdToken;

  @override
  final String uid;

  final Future<String?> Function(bool forceRefresh) _onGetIdToken;
  int getIdTokenCalls = 0;
  int reloadCalls = 0;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    getIdTokenCalls += 1;
    return _onGetIdToken(forceRefresh);
  }

  @override
  Future<void> reload() async {
    reloadCalls += 1;
  }
}

void main() {
  group('AuthRemoteDataSourceImpl.refreshSecurityContext', () {
    late MockFirebaseAuth mockAuth;
    late _FakeAppCheck fakeAppCheck;
    late AuthRemoteDataSourceImpl dataSource;
    late Completer<String?> tokenCompleter;
    late _TestUser testUser;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      fakeAppCheck = _FakeAppCheck();
      tokenCompleter = Completer<String?>();
      testUser = _TestUser(
        uid: 'user-1',
        onGetIdToken: (_) => tokenCompleter.future,
      );

      when(mockAuth.currentUser).thenReturn(testUser);

      dataSource = AuthRemoteDataSourceImpl(
        mockAuth,
        FakeFirebaseFirestore(),
        functions: _FakeFirebaseFunctions(),
        appCheck: fakeAppCheck,
      );
    });

    test('coalesces concurrent refresh requests', () async {
      final firstRefresh = dataSource.refreshSecurityContext();
      final secondRefresh = dataSource.refreshSecurityContext();

      tokenCompleter.complete('auth-token');
      await Future.wait([firstRefresh, secondRefresh]);

      expect(testUser.getIdTokenCalls, 1);
      expect(testUser.reloadCalls, 1);
      expect(fakeAppCheck.cachedTokenCalls, 1);
    });
  });
}
