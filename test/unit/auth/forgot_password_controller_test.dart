import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/presentation/forgot_password_screen.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
import 'forgot_password_controller_test.mocks.dart';

void main() {
  // Provide dummy values for Either type used in mocks
  setUpAll(() {
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });
  group('ForgotPasswordController', () {
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

    group('sendResetEmail', () {
      const email = 'test@example.com';

      test('should set state to AsyncLoading when called', () async {
        // Arrange
        when(
          mockAuthRepository.sendPasswordResetEmail(email),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(
          forgotPasswordControllerProvider.notifier,
        );

        // Act
        final future = controller.sendResetEmail(email: email);

        // Assert - verify loading state
        expect(
          container.read(forgotPasswordControllerProvider).isLoading,
          true,
        );

        // Wait for completion
        await future;
      });

      test('should set state to AsyncData on successful email send', () async {
        // Arrange
        when(
          mockAuthRepository.sendPasswordResetEmail(email),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(
          forgotPasswordControllerProvider.notifier,
        );

        // Act
        await controller.sendResetEmail(email: email);

        // Assert
        final state = container.read(forgotPasswordControllerProvider);
        expect(state.hasValue, true);
        verify(mockAuthRepository.sendPasswordResetEmail(email)).called(1);
      });

      test('should set state to AsyncError on FirebaseAuthException', () async {
        // Arrange
        const failure = AuthFailure(message: 'User not found');
        when(
          mockAuthRepository.sendPasswordResetEmail(email),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(
          forgotPasswordControllerProvider.notifier,
        );

        // Act
        await controller.sendResetEmail(email: email);

        // Assert
        final state = container.read(forgotPasswordControllerProvider);
        expect(state.hasError, true);
        expect(state.error, 'User not found');
      });

      test('should set state to AsyncError on generic exception', () async {
        // Arrange
        const failure = ServerFailure(message: 'Network error');
        when(
          mockAuthRepository.sendPasswordResetEmail(email),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(
          forgotPasswordControllerProvider.notifier,
        );

        // Act
        await controller.sendResetEmail(email: email);

        // Assert
        final state = container.read(forgotPasswordControllerProvider);
        expect(state.hasError, true);
        expect(state.error, 'Network error');
      });

      test('should handle empty email gracefully', () async {
        // Arrange
        const emptyEmail = '';
        const failure = AuthFailure(message: 'Invalid email');
        when(
          mockAuthRepository.sendPasswordResetEmail(emptyEmail),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(
          forgotPasswordControllerProvider.notifier,
        );

        // Act
        await controller.sendResetEmail(email: emptyEmail);

        // Assert
        final state = container.read(forgotPasswordControllerProvider);
        expect(state.hasError, true);
        expect(state.error, 'Invalid email');
      });

      test('should handle invalid email format', () async {
        // Arrange
        const invalidEmail = 'not-an-email';
        const failure = AuthFailure(message: 'Invalid email format');
        when(
          mockAuthRepository.sendPasswordResetEmail(invalidEmail),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(
          forgotPasswordControllerProvider.notifier,
        );

        // Act
        await controller.sendResetEmail(email: invalidEmail);

        // Assert
        final state = container.read(forgotPasswordControllerProvider);
        expect(state.hasError, true);
        expect(state.error, 'Invalid email format');
      });

      test('should handle user not found error', () async {
        // Arrange
        const nonExistentEmail = 'nonexistent@example.com';
        final failure = AuthFailure.userNotFound();
        when(
          mockAuthRepository.sendPasswordResetEmail(nonExistentEmail),
        ).thenAnswer((_) async => Left(failure));

        final controller = container.read(
          forgotPasswordControllerProvider.notifier,
        );

        // Act
        await controller.sendResetEmail(email: nonExistentEmail);

        // Assert
        final state = container.read(forgotPasswordControllerProvider);
        expect(state.hasError, true);
        expect(state.error, 'Usuário não encontrado.');
      });
    });

    group('state transitions', () {
      const email = 'test@example.com';

      test('should transition from idle to loading to success', () async {
        // Arrange
        when(
          mockAuthRepository.sendPasswordResetEmail(email),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(
          forgotPasswordControllerProvider.notifier,
        );
        final states = <AsyncValue<void>>[];

        // Listen to state changes
        container.listen(
          forgotPasswordControllerProvider,
          (previous, next) => states.add(next),
          fireImmediately: false,
        );

        // Act
        await controller.sendResetEmail(email: email);

        // Assert
        expect(states.length, 2);
        expect(states[0].isLoading, true); // First transition to loading
        expect(states[1].hasValue, true); // Then to success
      });

      test('should transition from idle to loading to error', () async {
        // Arrange
        const failure = AuthFailure(message: 'Error');
        when(
          mockAuthRepository.sendPasswordResetEmail(email),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(
          forgotPasswordControllerProvider.notifier,
        );
        final states = <AsyncValue<void>>[];

        // Listen to state changes
        container.listen(
          forgotPasswordControllerProvider,
          (previous, next) => states.add(next),
          fireImmediately: false,
        );

        // Act
        await controller.sendResetEmail(email: email);

        // Assert
        expect(states.length, 2);
        expect(states[0].isLoading, true); // First transition to loading
        expect(states[1].hasError, true); // Then to error
      });
    });
  });
}
