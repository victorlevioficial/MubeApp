import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';

import '../../helpers/firebase_mocks.dart';

class _FakeHttpsCallableResult<T> extends Fake
    implements HttpsCallableResult<T> {
  _FakeHttpsCallableResult(this._data);

  final T _data;

  @override
  T get data => _data;
}

typedef _CallableHandler =
    Future<HttpsCallableResult<dynamic>> Function(Object? parameters);

class _FakeHttpsCallable extends Fake implements HttpsCallable {
  _FakeHttpsCallable(this.name, this.invocations, {this.handler});

  final String name;
  final List<Map<String, Object?>> invocations;
  final _CallableHandler? handler;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    invocations.add({'name': name, 'parameters': parameters});
    if (handler != null) {
      return (await handler!(parameters)) as HttpsCallableResult<T>;
    }
    return _FakeHttpsCallableResult<T>(
      (<String, dynamic>{'success': true}) as T,
    );
  }
}

class _FakeFunctions extends Fake implements FirebaseFunctions {
  _FakeFunctions({this.handlers = const {}});

  final Map<String, _CallableHandler> handlers;
  final List<Map<String, Object?>> invocations = [];

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    return _FakeHttpsCallable(name, invocations, handler: handlers[name]);
  }
}

class _FakeAppCheck extends Fake implements app_check.FirebaseAppCheck {
  int cachedTokenCalls = 0;

  @override
  Future<String?> getToken([bool? forceRefresh]) async {
    cachedTokenCalls += 1;
    return 'app-check-token';
  }
}

class _TestUser extends Fake implements User {
  _TestUser({required this.uid});

  @override
  final String uid;

  int getIdTokenCalls = 0;
  int reloadCalls = 0;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    getIdTokenCalls += 1;
    return 'auth-token';
  }

  @override
  Future<void> reload() async {
    reloadCalls += 1;
  }
}

void main() {
  group('AuthRemoteDataSourceImpl public username', () {
    test('calls the callable function with a normalized username', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();
      final user = _TestUser(uid: 'user-1');
      final appCheck = _FakeAppCheck();
      when(auth.currentUser).thenReturn(user);
      final functions = _FakeFunctions(
        handlers: {
          'setPublicUsername': (parameters) async {
            return _FakeHttpsCallableResult(<String, dynamic>{
              'username': 'mube.oficial',
            });
          },
        },
      );
      final dataSource = AuthRemoteDataSourceImpl(
        auth,
        firestore,
        functions: functions,
        publicUsernameFunctions: functions,
        appCheck: appCheck,
      );

      final result = await dataSource.updatePublicUsername('@Mube.Oficial');

      expect(result, 'mube.oficial');
      expect(user.getIdTokenCalls, 1);
      expect(user.reloadCalls, 1);
      expect(appCheck.cachedTokenCalls, 1);
      expect(functions.invocations, hasLength(1));
      expect(functions.invocations.single['parameters'], <String, dynamic>{
        'username': 'mube.oficial',
      });
    });

    test(
      'retries recoverable unauthenticated errors after refreshing security context',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth();
        final user = _TestUser(uid: 'user-1');
        final appCheck = _FakeAppCheck();
        when(auth.currentUser).thenReturn(user);

        var attempts = 0;
        final functions = _FakeFunctions(
          handlers: {
            'setPublicUsername': (_) async {
              attempts += 1;
              if (attempts == 1) {
                throw FirebaseFunctionsException(
                  code: 'unauthenticated',
                  message: 'Auth token missing.',
                );
              }

              return _FakeHttpsCallableResult(<String, dynamic>{
                'username': 'mube.oficial',
              });
            },
          },
        );
        final dataSource = AuthRemoteDataSourceImpl(
          auth,
          firestore,
          functions: functions,
          publicUsernameFunctions: functions,
          appCheck: appCheck,
        );

        final result = await dataSource.updatePublicUsername('mube.oficial');

        expect(result, 'mube.oficial');
        expect(functions.invocations, hasLength(2));
        expect(user.getIdTokenCalls, 2);
        expect(user.reloadCalls, 2);
        expect(appCheck.cachedTokenCalls, 2);
      },
    );

    test('maps already-exists errors to a user-friendly exception', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();
      final user = _TestUser(uid: 'user-1');
      when(auth.currentUser).thenReturn(user);
      final functions = _FakeFunctions(
        handlers: {
          'setPublicUsername': (_) async => throw FirebaseFunctionsException(
            code: 'already-exists',
            message: 'Esse @usuario ja esta em uso. Escolha outro.',
          ),
        },
      );
      final dataSource = AuthRemoteDataSourceImpl(
        auth,
        firestore,
        functions: functions,
        publicUsernameFunctions: functions,
        appCheck: _FakeAppCheck(),
      );

      await expectLater(
        dataSource.updatePublicUsername('mube.oficial'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Esse @usuario ja esta em uso. Escolha outro.'),
          ),
        ),
      );
    });

    test(
      'maps app check failures to a security validation exception even when code is unauthenticated',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth();
        final user = _TestUser(uid: 'user-1');
        when(auth.currentUser).thenReturn(user);
        final functions = _FakeFunctions(
          handlers: {
            'setPublicUsername': (_) async => throw FirebaseFunctionsException(
              code: 'unauthenticated',
              message:
                  'Callable request verification failed: AppCheck token was rejected.',
            ),
          },
        );
        final dataSource = AuthRemoteDataSourceImpl(
          auth,
          firestore,
          functions: functions,
          publicUsernameFunctions: functions,
          appCheck: _FakeAppCheck(),
        );

        await expectLater(
          dataSource.updatePublicUsername('mube.oficial'),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Falha na validacao de seguranca do app'),
            ),
          ),
        );
      },
    );

    test(
      'maps unexpected not_found exceptions to a service unavailable message',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth();
        final user = _TestUser(uid: 'user-1');
        when(auth.currentUser).thenReturn(user);
        final functions = _FakeFunctions(
          handlers: {
            'setPublicUsername': (_) async => throw Exception('not_found'),
          },
        );
        final dataSource = AuthRemoteDataSourceImpl(
          auth,
          firestore,
          functions: functions,
          publicUsernameFunctions: functions,
          appCheck: _FakeAppCheck(),
        );

        await expectLater(
          dataSource.updatePublicUsername('mube.oficial'),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Servico de @usuario indisponivel'),
            ),
          ),
        );
      },
    );

    test(
      'does not persist username through direct user profile writes',
      () async {
        final firestore = FakeFirebaseFirestore();
        final dataSource = AuthRemoteDataSourceImpl(
          MockFirebaseAuth(),
          firestore,
          functions: _FakeFunctions(),
          publicUsernameFunctions: _FakeFunctions(),
          appCheck: _FakeAppCheck(),
        );
        const user = AppUser(
          uid: 'user-1',
          email: 'user@example.com',
          cadastroStatus: 'concluido',
          username: 'mube.oficial',
        );

        await dataSource.updateUserProfile(user);

        final snapshot = await firestore
            .collection('users')
            .doc('user-1')
            .get();
        expect(snapshot.exists, true);
        expect(
          snapshot.data(),
          isNot(containsPair('username', 'mube.oficial')),
        );
      },
    );
  });
}
