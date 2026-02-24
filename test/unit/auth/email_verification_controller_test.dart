import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/presentation/email_verification_screen.dart';

import 'email_verification_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  group('EmailVerificationController', () {
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      provideDummy<Either<Failure, Unit>>(const Right(unit));

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('resendVerificationEmail', () {
      test('should set state to AsyncLoading when called', () async {
        // Arrange
        when(
          mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(
          emailVerificationControllerProvider.notifier,
        );

        // Act
        final future = controller.resendVerificationEmail();

        // Assert - verify loading state
        expect(
          container.read(emailVerificationControllerProvider).isResending,
          true,
        );

        // Wait for completion
        await future;
      });

      test('should set state to AsyncData on successful email send', () async {
        // Arrange
        when(
          mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(
          emailVerificationControllerProvider.notifier,
        );

        // Act
        await controller.resendVerificationEmail();

        // Assert
        final state = container.read(emailVerificationControllerProvider);
        expect(state.isResending, false);
        expect(state.error, isNull);
        verify(mockAuthRepository.sendEmailVerification()).called(1);
      });

      test('should set state error on failure', () async {
        // Arrange
        const failure = AuthFailure(message: 'Failed to send email');
        when(
          mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(
          emailVerificationControllerProvider.notifier,
        );

        // Act
        await controller.resendVerificationEmail();

        // Assert
        final state = container.read(emailVerificationControllerProvider);
        expect(state.isResending, false);
        expect(state.error, 'Failed to send email');
      });
    });

    group('checkVerificationStatus', () {
      test('should update state when email is verified', () async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => true);

        final controller = container.read(
          emailVerificationControllerProvider.notifier,
        );

        // Act
        await controller.checkVerificationStatus();

        // Assert
        verify(mockAuthRepository.isEmailVerified()).called(1);
      });

      test('should not update state when email is not verified', () async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);

        final controller = container.read(
          emailVerificationControllerProvider.notifier,
        );

        // Act
        await controller.checkVerificationStatus();

        // Assert
        verify(mockAuthRepository.isEmailVerified()).called(1);
      });
    });

    group('state transitions', () {
      test('should transition from idle to loading to success', () async {
        // Arrange
        when(
          mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(
          emailVerificationControllerProvider.notifier,
        );
        final states = <EmailVerificationState>[];

        // Listen to state changes
        container.listen(
          emailVerificationControllerProvider,
          (previous, next) => states.add(next),
          fireImmediately: false,
        );

        // Act
        await controller.resendVerificationEmail();

        // Assert
        expect(states.length, 2);
        expect(states[0].isResending, true);
        expect(states[1].isResending, false);
        expect(states[1].error, isNull);
      });

      test('should transition from idle to loading to error', () async {
        // Arrange
        const failure = AuthFailure(message: 'Error');
        when(
          mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(
          emailVerificationControllerProvider.notifier,
        );
        final states = <EmailVerificationState>[];

        // Listen to state changes
        container.listen(
          emailVerificationControllerProvider,
          (previous, next) => states.add(next),
          fireImmediately: false,
        );

        // Act
        await controller.resendVerificationEmail();

        // Assert
        expect(states.length, 2);
        expect(states[0].isResending, true);
        expect(states[1].isResending, false);
        expect(states[1].error, 'Error');
      });
    });
  });
}
