import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:flutter_test/flutter_test.dart';
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
  @override
  Future<String?> getToken([bool? forceRefresh]) async => 'app-check-token';
}

void main() {
  group('AuthRemoteDataSourceImpl public username', () {
    test('calls the callable function with a normalized username', () async {
      final firestore = FakeFirebaseFirestore();
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
        MockFirebaseAuth(),
        firestore,
        functions: functions,
        publicUsernameFunctions: functions,
        appCheck: _FakeAppCheck(),
      );

      final result = await dataSource.updatePublicUsername('@Mube.Oficial');

      expect(result, 'mube.oficial');
      expect(functions.invocations, hasLength(1));
      expect(functions.invocations.single['parameters'], <String, dynamic>{
        'username': 'mube.oficial',
      });
    });

    test('maps already-exists errors to a user-friendly exception', () async {
      final firestore = FakeFirebaseFirestore();
      final functions = _FakeFunctions(
        handlers: {
          'setPublicUsername': (_) async => throw FirebaseFunctionsException(
            code: 'already-exists',
            message: 'Esse @usuario ja esta em uso. Escolha outro.',
          ),
        },
      );
      final dataSource = AuthRemoteDataSourceImpl(
        MockFirebaseAuth(),
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
