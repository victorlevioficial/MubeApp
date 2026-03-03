import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository.refreshSecurityContext', () {
    late _RefreshSecurityContextDataSource dataSource;
    late AuthRepository repository;

    setUp(() {
      dataSource = _RefreshSecurityContextDataSource();
      repository = AuthRepository(dataSource);
    });

    test(
      'returns session-expired when there is no authenticated user',
      () async {
        final result = await repository.refreshSecurityContext();

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Sua sessão expirou. Faça login novamente.');
        }, (_) => fail('Expected Left'));
        expect(dataSource.refreshCalls, 0);
      },
    );

    test('refreshes the security context for an authenticated user', () async {
      dataSource.currentUserValue = _TestUser(uid: 'user-1');

      final result = await repository.refreshSecurityContext();

      expect(result.isRight(), true);
      expect(dataSource.refreshCalls, 1);
    });

    test('maps terminal auth refresh errors to session-expired', () async {
      dataSource.currentUserValue = _TestUser(uid: 'user-1');
      dataSource.refreshError = FirebaseAuthException(
        code: 'user-token-expired',
        message: 'Token expired',
      );

      final result = await repository.refreshSecurityContext();

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Sua sessão expirou. Faça login novamente.');
        expect(failure.debugMessage, 'user-token-expired');
      }, (_) => fail('Expected Left'));
      expect(dataSource.refreshCalls, 1);
    });
  });
}

class _RefreshSecurityContextDataSource implements AuthRemoteDataSource {
  User? currentUserValue;
  Object? refreshError;
  int refreshCalls = 0;

  @override
  User? get currentUser => currentUserValue;

  @override
  Future<void> refreshSecurityContext() async {
    refreshCalls++;
    if (refreshError != null) throw refreshError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestUser implements User {
  final String _uid;

  _TestUser({required String uid}) : _uid = uid;

  @override
  String get uid => _uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
