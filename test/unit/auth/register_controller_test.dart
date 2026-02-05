import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/presentation/register_controller.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>(), MockSpec<AnalyticsService>()])
import 'register_controller_test.mocks.dart';

void main() {
  // Provide dummy values for Either type used in mocks
  setUpAll(() {
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  group('RegisterController', () {
    late MockAuthRepository mockAuthRepository;
    late MockAnalyticsService mockAnalyticsService;
    late ProviderContainer container;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockAnalyticsService = MockAnalyticsService();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should have AsyncData(null) as initial state', () {
      // Act
      final state = container.read(registerControllerProvider);

      // Assert
      expect(state.hasValue, true);
      expect((state as AsyncData).value, null);
    });

    group('register', () {
      const email = 'test@example.com';
      const password = 'password123';

      test('should set state to AsyncLoading when called', () async {
        // Arrange
        when(
          mockAuthRepository.registerWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(registerControllerProvider.notifier);

        // Act
        final future = controller.register(email: email, password: password);

        // Assert - verify loading state
        expect(container.read(registerControllerProvider).isLoading, true);

        // Wait for completion
        await future;
      });

      test(
        'should set state to AsyncData(null) on successful registration',
        () async {
          // Arrange
          when(
            mockAuthRepository.registerWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).thenAnswer((_) async => const Right(unit));

          final controller = container.read(
            registerControllerProvider.notifier,
          );

          // Act
          await controller.register(email: email, password: password);

          // Assert
          final state = container.read(registerControllerProvider);
          expect(state.hasValue, true);
          expect((state as AsyncData).value, null);
          verify(
            mockAuthRepository.registerWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).called(1);
        },
      );

      test('should call repository with correct parameters', () async {
        // Arrange
        when(
          mockAuthRepository.registerWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(registerControllerProvider.notifier);

        // Act
        await controller.register(email: email, password: password);

        // Assert
        verify(
          mockAuthRepository.registerWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test(
        'should set state to AsyncError on email already in use failure',
        () async {
          // Arrange
          const errorMessage = 'Este e-mail já está cadastrado.';
          final failure = AuthFailure.emailAlreadyInUse();
          when(
            mockAuthRepository.registerWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).thenAnswer((_) async => Left(failure));

          final controller = container.read(
            registerControllerProvider.notifier,
          );

          // Act
          await controller.register(email: email, password: password);

          // Assert
          final state = container.read(registerControllerProvider);
          expect(state.hasError, true);
          expect(state.error, errorMessage);
        },
      );

      test('should set state to AsyncError on generic failure', () async {
        // Arrange
        const errorMessage = 'Registration failed';
        const failure = AuthFailure(message: errorMessage);
        when(
          mockAuthRepository.registerWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(registerControllerProvider.notifier);

        // Act
        await controller.register(email: email, password: password);

        // Assert
        final state = container.read(registerControllerProvider);
        expect(state.hasError, true);
        expect(state.error, errorMessage);
        verify(
          mockAuthRepository.registerWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test(
        'should set state to AsyncError with correct error message',
        () async {
          // Arrange
          const errorMessage = 'Network error';
          const failure = ServerFailure(message: errorMessage);
          when(
            mockAuthRepository.registerWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).thenAnswer((_) async => const Left(failure));

          final controller = container.read(
            registerControllerProvider.notifier,
          );

          // Act
          await controller.register(email: email, password: password);

          // Assert
          final state = container.read(registerControllerProvider);
          expect(state.hasError, true);
          expect(state.error, errorMessage);
          verify(
            mockAuthRepository.registerWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).called(1);
        },
      );

      test('should handle weak password error', () async {
        // Arrange
        const errorMessage = 'Senha muito fraca. Use pelo menos 6 caracteres.';
        final failure = AuthFailure.weakPassword();
        when(
          mockAuthRepository.registerWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => Left(failure));

        final controller = container.read(registerControllerProvider.notifier);

        // Act
        await controller.register(email: email, password: password);

        // Assert
        final state = container.read(registerControllerProvider);
        expect(state.hasError, true);
        expect(state.error, errorMessage);
      });

      test('should handle invalid email error', () async {
        // Arrange
        const errorMessage = 'E-mail inválido.';
        final failure = AuthFailure.invalidEmail();
        when(
          mockAuthRepository.registerWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => Left(failure));

        final controller = container.read(registerControllerProvider.notifier);

        // Act
        await controller.register(email: email, password: password);

        // Assert
        final state = container.read(registerControllerProvider);
        expect(state.hasError, true);
        expect(state.error, errorMessage);
      });
    });
  });
}
