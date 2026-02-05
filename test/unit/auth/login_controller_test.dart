import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/presentation/login_screen.dart';

import 'login_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  // Provide dummy values for Either type used in mocks
  setUpAll(() {
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  group('LoginController', () {
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should have AsyncData(null) as initial state', () {
      // Act
      final state = container.read(loginControllerProvider);

      // Assert
      expect(state.hasValue, true);
      expect((state as AsyncData).value, null);
    });

    group('login', () {
      const email = 'test@example.com';
      const password = 'password123';

      test('should set state to AsyncLoading when called', () async {
        // Arrange
        when(
          mockAuthRepository.signInWithEmailAndPassword(email, password),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(loginControllerProvider.notifier);

        // Act
        final future = controller.login(email: email, password: password);

        // Assert - verify loading state
        expect(container.read(loginControllerProvider).isLoading, true);

        // Wait for completion
        await future;
      });

      test('should set state to AsyncData(null) on successful login', () async {
        // Arrange
        when(
          mockAuthRepository.signInWithEmailAndPassword(email, password),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(loginControllerProvider.notifier);

        // Act
        await controller.login(email: email, password: password);

        // Assert
        final state = container.read(loginControllerProvider);
        expect(state.hasValue, true);
        expect((state as AsyncData).value, null);
        verify(
          mockAuthRepository.signInWithEmailAndPassword(email, password),
        ).called(1);
      });

      test('should call repository with correct parameters', () async {
        // Arrange
        when(
          mockAuthRepository.signInWithEmailAndPassword(email, password),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(loginControllerProvider.notifier);

        // Act
        await controller.login(email: email, password: password);

        // Assert
        verify(
          mockAuthRepository.signInWithEmailAndPassword(email, password),
        ).called(1);
      });

      test('should set state to AsyncError on failure', () async {
        // Arrange
        const errorMessage = 'Invalid credentials';
        const failure = AuthFailure(message: errorMessage);
        when(
          mockAuthRepository.signInWithEmailAndPassword(email, password),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(loginControllerProvider.notifier);

        // Act
        await controller.login(email: email, password: password);

        // Assert
        final state = container.read(loginControllerProvider);
        expect(state.hasError, true);
        expect(state.error, errorMessage);
      });

      test(
        'should set state to AsyncError with correct error message',
        () async {
          // Arrange
          const errorMessage = 'User not found';
          const failure = AuthFailure(message: errorMessage);
          when(
            mockAuthRepository.signInWithEmailAndPassword(email, password),
          ).thenAnswer((_) async => const Left(failure));

          final controller = container.read(loginControllerProvider.notifier);

          // Act
          await controller.login(email: email, password: password);

          // Assert
          final state = container.read(loginControllerProvider);
          expect(state.hasError, true);
          expect(state.error, errorMessage);
          verify(
            mockAuthRepository.signInWithEmailAndPassword(email, password),
          ).called(1);
        },
      );

      test('should handle ServerFailure correctly', () async {
        // Arrange
        const errorMessage = 'Network error';
        const failure = ServerFailure(message: errorMessage);
        when(
          mockAuthRepository.signInWithEmailAndPassword(email, password),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(loginControllerProvider.notifier);

        // Act
        await controller.login(email: email, password: password);

        // Assert
        final state = container.read(loginControllerProvider);
        expect(state.hasError, true);
        expect(state.error, errorMessage);
      });
    });
  });
}
