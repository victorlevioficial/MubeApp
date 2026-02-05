import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';

@GenerateNiceMocks([MockSpec<AuthRemoteDataSource>()])
import 'auth_repository_test.mocks.dart';

void main() {
  late AuthRepository repository;
  late MockAuthRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepository(mockDataSource);
  });

  group('AuthRepository', () {
    group('signInWithEmailAndPassword', () {
      const email = 'test@example.com';
      const password = 'password123';

      test('should return Right(Unit) on successful sign in', () async {
        // Arrange
        when(
          mockDataSource.signInWithEmailAndPassword(email, password),
        ).thenAnswer((_) async => {});

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email,
          password,
        );

        // Assert
        expect(result.isRight(), true);
        verify(
          mockDataSource.signInWithEmailAndPassword(email, password),
        ).called(1);
      });

      test(
        'should return Left(AuthFailure) on FirebaseAuthException',
        () async {
          // Arrange
          final exception = FirebaseAuthException(
            code: 'user-not-found',
            message: 'User not found',
          );
          when(
            mockDataSource.signInWithEmailAndPassword(email, password),
          ).thenThrow(exception);

          // Act
          final result = await repository.signInWithEmailAndPassword(
            email,
            password,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<AuthFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test('should return Left(AuthFailure) on generic exception', () async {
        // Arrange
        when(
          mockDataSource.signInWithEmailAndPassword(email, password),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email,
          password,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, contains('Network error'));
        }, (_) => fail('Expected Left'));
      });
    });

    group('registerWithEmailAndPassword', () {
      const email = 'newuser@example.com';
      const password = 'newpassword123';
      const uid = 'test-uid-123';

      test('should return Right(Unit) on successful registration', () async {
        // Arrange
        final mockUser = _MockUser(uid: uid);
        when(
          mockDataSource.registerWithEmailAndPassword(email, password),
        ).thenAnswer((_) async => mockUser);
        when(mockDataSource.saveUserProfile(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.registerWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isRight(), true);
        verify(
          mockDataSource.registerWithEmailAndPassword(email, password),
        ).called(1);
        verify(mockDataSource.saveUserProfile(any)).called(1);
      });

      test('should return Right(Unit) even if user is null', () async {
        // Arrange
        when(
          mockDataSource.registerWithEmailAndPassword(email, password),
        ).thenAnswer((_) async => null);

        // Act
        final result = await repository.registerWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isRight(), true);
        verify(
          mockDataSource.registerWithEmailAndPassword(email, password),
        ).called(1);
        verifyNever(mockDataSource.saveUserProfile(any));
      });

      test(
        'should return Left(AuthFailure) on FirebaseAuthException',
        () async {
          // Arrange
          final exception = FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Email already exists',
          );
          when(
            mockDataSource.registerWithEmailAndPassword(email, password),
          ).thenThrow(exception);

          // Act
          final result = await repository.registerWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<AuthFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });

    group('signOut', () {
      test('should return Right(Unit) on successful sign out', () async {
        // Arrange
        when(mockDataSource.signOut()).thenAnswer((_) async => {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isRight(), true);
        verify(mockDataSource.signOut()).called(1);
      });

      test('should return Left(AuthFailure) on exception', () async {
        // Arrange
        when(mockDataSource.signOut()).thenThrow(Exception('Sign out failed'));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, contains('Sign out failed'));
        }, (_) => fail('Expected Left'));
      });
    });

    group('updateUser', () {
      const testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        cadastroStatus: 'tipo_pendente',
      );

      test('should return Right(Unit) on successful update', () async {
        // Arrange
        when(mockDataSource.updateUserProfile(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.updateUser(testUser);

        // Assert
        expect(result.isRight(), true);
        verify(mockDataSource.updateUserProfile(testUser)).called(1);
      });

      test('should return Left(ServerFailure) on exception', () async {
        // Arrange
        when(
          mockDataSource.updateUserProfile(any),
        ).thenThrow(Exception('Update failed'));

        // Act
        final result = await repository.updateUser(testUser);

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Update failed'));
        }, (_) => fail('Expected Left'));
      });
    });

    group('getUsersByIds', () {
      final testUids = ['uid1', 'uid2'];
      final testUsers = [
        const AppUser(
          uid: 'uid1',
          email: 'user1@example.com',
          cadastroStatus: 'concluido',
        ),
        const AppUser(
          uid: 'uid2',
          email: 'user2@example.com',
          cadastroStatus: 'concluido',
        ),
      ];

      test('should return Right(List<AppUser>) on success', () async {
        // Arrange
        when(
          mockDataSource.fetchUsersByIds(testUids),
        ).thenAnswer((_) async => testUsers);

        // Act
        final result = await repository.getUsersByIds(testUids);

        // Assert
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected Right'), (users) {
          expect(users.length, 2);
          expect(users[0].uid, 'uid1');
          expect(users[1].uid, 'uid2');
        });
      });

      test('should return Left(ServerFailure) on exception', () async {
        // Arrange
        when(
          mockDataSource.fetchUsersByIds(testUids),
        ).thenThrow(Exception('Fetch failed'));

        // Act
        final result = await repository.getUsersByIds(testUids);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('authStateChanges', () {
      test('should delegate to dataSource.authStateChanges', () {
        // Arrange
        final mockStream = Stream<User?>.value(null);
        when(mockDataSource.authStateChanges()).thenAnswer((_) => mockStream);

        // Act
        final result = repository.authStateChanges();

        // Assert
        expect(result, equals(mockStream));
        verify(mockDataSource.authStateChanges()).called(1);
      });
    });

    group('currentUser', () {
      test('should delegate to dataSource.currentUser', () {
        // Arrange
        final mockUser = _MockUser(uid: 'test-uid');
        when(mockDataSource.currentUser).thenReturn(mockUser);

        // Act
        final result = repository.currentUser;

        // Assert
        expect(result, equals(mockUser));
        verify(mockDataSource.currentUser).called(1);
      });
    });
  });
}

// Simple mock implementation for User
class _MockUser implements User {
  final String _uid;

  _MockUser({required String uid}) : _uid = uid;

  @override
  String get uid => _uid;

  // Implement other required methods as stubs
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
