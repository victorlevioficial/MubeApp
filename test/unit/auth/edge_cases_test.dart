import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';

@GenerateNiceMocks([MockSpec<AuthRemoteDataSource>()])
import 'edge_cases_test.mocks.dart';

void main() {
  late AuthRepository repository;
  late MockAuthRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepository(mockDataSource);
  });

  group('AuthRepository Edge Cases (Network & Timeout)', () {
    const email = 'edge@cases.com';
    const password = 'password123';

    test(
      'should return AuthFailure when login times out (Simulated)',
      () async {
        // Arrange
        when(mockDataSource.signInWithEmailAndPassword(any, any)).thenAnswer(
          (_) => Future.error(TimeoutException('Connection timed out')),
        );

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email,
          password,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, contains('Connection timed out'));
        }, (_) => fail('Should have failed'));
      },
    );

    test(
      'should handle network-request-failed (Firebase specific error)',
      () async {
        // Arrange
        final exception = FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Firebase specific network error message',
        );
        when(
          mockDataSource.signInWithEmailAndPassword(any, any),
        ).thenThrow(exception);

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email,
          password,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          // It seems it falls through to default: 'Ocorreu um erro no servidor. Tente novamente mais tarde. (network-request-failed)'
          expect(failure.message, contains('Erro de conexão'));
        }, (_) => fail('Should have failed'));
      },
    );

    test(
      'should handle transient connectivity loss during registration (Save Profile Failure)',
      () async {
        // Arrange
        final mockUser = _MockUser(uid: 'transient-uid');
        when(
          mockDataSource.registerWithEmailAndPassword(any, any),
        ).thenAnswer((_) async => mockUser);

        // Simulating that registration works but the secondary step (save profile) fails due to network
        when(
          mockDataSource.saveUserProfile(any),
        ).thenThrow(Exception('SocketException: Connection reset by peer'));

        // Act
        final result = await repository.registerWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          // Non-FirebaseAuthException goes to "Ocorreu um erro inesperado. Tente novamente."
          (failure) => expect(failure.message, contains('erro inesperado')),
          (_) => fail('Should have failed at profile save'),
        );
      },
    );
  });
}

// Simple mock implementation for User
class _MockUser implements User {
  final String _uid;
  _MockUser({required String uid}) : _uid = uid;

  @override
  String get uid => _uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
