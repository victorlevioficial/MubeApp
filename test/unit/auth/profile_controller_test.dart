import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/profile/presentation/profile_controller.dart';
import 'package:mube/src/features/storage/data/storage_repository.dart';
import 'package:mube/src/shared/services/content_moderation_service.dart';

import 'profile_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<StorageRepository>(),
  MockSpec<ContentModerationService>(),
  MockSpec<AnalyticsService>(),
])
void main() {
  // Provide dummy values for Either type used in mocks
  setUpAll(() {
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  group('ProfileController', () {
    late MockAuthRepository mockAuthRepository;
    late MockStorageRepository mockStorageRepository;
    late MockContentModerationService mockContentModerationService;
    late MockAnalyticsService mockAnalyticsService;
    late ProviderContainer container;

    // Sample user for testing
    const testUser = AppUser(
      uid: 'test-uid-123',
      email: 'test@example.com',
      nome: 'Test User',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
    );

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockStorageRepository = MockStorageRepository();
      mockContentModerationService = MockContentModerationService();
      mockAnalyticsService = MockAnalyticsService();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          storageRepositoryProvider.overrideWithValue(mockStorageRepository),
          contentModerationServiceProvider.overrideWithValue(
            mockContentModerationService,
          ),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should have AsyncData(null) as initial state', () {
      // Act
      final state = container.read(profileControllerProvider);

      // Assert
      expect(state.hasValue, true);
      expect((state as AsyncData).value, null);
    });

    group('updateProfile', () {
      test('should set state to AsyncLoading when called', () async {
        // Arrange
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        final future = controller.updateProfile(
          currentUser: testUser,
          updates: {'nome': 'Updated Name'},
        );

        // Assert - verify loading state
        expect(container.read(profileControllerProvider).isLoading, true);

        // Wait for completion
        await future;
      });

      test(
        'should set state to AsyncData(null) on successful update',
        () async {
          // Arrange
          when(
            mockAuthRepository.updateUser(any),
          ).thenAnswer((_) async => const Right(unit));

          final controller = container.read(profileControllerProvider.notifier);

          // Act
          await controller.updateProfile(
            currentUser: testUser,
            updates: {'nome': 'Updated Name'},
          );

          // Assert
          final state = container.read(profileControllerProvider);
          expect(state.hasValue, true);
          expect((state as AsyncData).value, null);
          verify(mockAuthRepository.updateUser(any)).called(1);
        },
      );

      test('should call repository with updated user data', () async {
        // Arrange
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        await controller.updateProfile(
          currentUser: testUser,
          updates: {
            'nome': 'Updated Name',
            'location': {'cidade': 'São Paulo', 'estado': 'SP'},
          },
        );

        // Assert
        verify(mockAuthRepository.updateUser(any)).called(1);
      });

      test('should update dadosProfissional when provided', () async {
        // Arrange
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        final userWithProfissionalData = testUser.copyWith(
          dadosProfissional: {'instrumento': 'Guitarra'},
        );

        // Act
        await controller.updateProfile(
          currentUser: userWithProfissionalData,
          updates: {
            'dadosProfissional': {'experiencia': '5 anos'},
          },
        );

        // Assert
        verify(mockAuthRepository.updateUser(any)).called(1);
      });

      test('should update dadosEstudio when provided', () async {
        // Arrange
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        final userWithEstudioData = testUser.copyWith(
          dadosEstudio: {'nome': 'Studio A'},
        );

        // Act
        await controller.updateProfile(
          currentUser: userWithEstudioData,
          updates: {
            'dadosEstudio': {'equipamentos': 'Pro Tools'},
          },
        );

        // Assert
        verify(mockAuthRepository.updateUser(any)).called(1);
      });

      test('should update dadosBanda when provided', () async {
        // Arrange
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        final userWithBandaData = testUser.copyWith(
          dadosBanda: {'nome': 'Rock Band'},
        );

        // Act
        await controller.updateProfile(
          currentUser: userWithBandaData,
          updates: {
            'dadosBanda': {'genero': 'Rock'},
          },
        );

        // Assert
        verify(mockAuthRepository.updateUser(any)).called(1);
      });

      test('should update dadosContratante when provided', () async {
        // Arrange
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        final userWithContratanteData = testUser.copyWith(
          dadosContratante: {'empresa': 'Events Ltd'},
        );

        // Act
        await controller.updateProfile(
          currentUser: userWithContratanteData,
          updates: {
            'dadosContratante': {'tipo': 'Bar'},
          },
        );

        // Assert
        verify(mockAuthRepository.updateUser(any)).called(1);
      });

      test('should call analytics on successful update', () async {
        // Arrange
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        await controller.updateProfile(
          currentUser: testUser,
          updates: {'nome': 'Updated Name'},
        );

        // Assert
        verify(
          mockAnalyticsService.logProfileEdit(userId: testUser.uid),
        ).called(1);
      });

      test('should set state to AsyncError on failure', () async {
        // Arrange
        const errorMessage = 'Failed to update profile';
        const failure = ServerFailure(message: errorMessage);
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Left(failure));

        final controller = container.read(profileControllerProvider.notifier);

        // Act & Assert
        await expectLater(
          () => controller.updateProfile(
            currentUser: testUser,
            updates: {'nome': 'Updated Name'},
          ),
          throwsA(isA<Exception>()),
        );

        // Assert state
        final state = container.read(profileControllerProvider);
        expect(state.hasError, true);
        expect(state.error, errorMessage);
      });

      test(
        'should set state to AsyncError with correct error message',
        () async {
          // Arrange
          const errorMessage = 'Network error';
          const failure = NetworkFailure(message: errorMessage);
          when(
            mockAuthRepository.updateUser(any),
          ).thenAnswer((_) async => const Left(failure));

          final controller = container.read(profileControllerProvider.notifier);

          // Act & Assert
          await expectLater(
            () => controller.updateProfile(
              currentUser: testUser,
              updates: {'nome': 'Updated Name'},
            ),
            throwsA(isA<Exception>()),
          );

          // Assert state
          final state = container.read(profileControllerProvider);
          expect(state.hasError, true);
          expect(state.error, errorMessage);
        },
      );
    });

    group('updateProfileImage', () {
      late File mockFile;

      setUp(() {
        mockFile = File('test_image.jpg');
      });

      test('should set state to AsyncLoading when called', () async {
        // Arrange
        when(
          mockContentModerationService.validateImage(any),
        ).thenAnswer((_) async => true);
        when(
          mockStorageRepository.uploadProfileImage(
            userId: anyNamed('userId'),
            file: anyNamed('file'),
          ),
        ).thenAnswer((_) async => 'https://example.com/image.jpg');
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        final future = controller.updateProfileImage(
          file: mockFile,
          currentUser: testUser,
        );

        // Assert - verify loading state
        expect(container.read(profileControllerProvider).isLoading, true);

        // Wait for completion
        await future;
      });

      test('should validate image before upload', () async {
        // Arrange
        when(
          mockContentModerationService.validateImage(any),
        ).thenAnswer((_) async => true);
        when(
          mockStorageRepository.uploadProfileImage(
            userId: anyNamed('userId'),
            file: anyNamed('file'),
          ),
        ).thenAnswer((_) async => 'https://example.com/image.jpg');
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        await controller.updateProfileImage(
          file: mockFile,
          currentUser: testUser,
        );

        // Assert
        verify(mockContentModerationService.validateImage(mockFile)).called(1);
      });

      test('should upload image to storage', () async {
        // Arrange
        when(
          mockContentModerationService.validateImage(any),
        ).thenAnswer((_) async => true);
        when(
          mockStorageRepository.uploadProfileImage(
            userId: anyNamed('userId'),
            file: anyNamed('file'),
          ),
        ).thenAnswer((_) async => 'https://example.com/image.jpg');
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        await controller.updateProfileImage(
          file: mockFile,
          currentUser: testUser,
        );

        // Assert
        verify(
          mockStorageRepository.uploadProfileImage(
            userId: testUser.uid,
            file: mockFile,
          ),
        ).called(1);
      });

      test('should update user with new photo URL', () async {
        // Arrange
        const downloadUrl = 'https://example.com/image.jpg';
        when(
          mockContentModerationService.validateImage(any),
        ).thenAnswer((_) async => true);
        when(
          mockStorageRepository.uploadProfileImage(
            userId: anyNamed('userId'),
            file: anyNamed('file'),
          ),
        ).thenAnswer((_) async => downloadUrl);
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        await controller.updateProfileImage(
          file: mockFile,
          currentUser: testUser,
        );

        // Assert
        verify(mockAuthRepository.updateUser(any)).called(1);
      });

      test('should call analytics on successful image update', () async {
        // Arrange
        when(
          mockContentModerationService.validateImage(any),
        ).thenAnswer((_) async => true);
        when(
          mockStorageRepository.uploadProfileImage(
            userId: anyNamed('userId'),
            file: anyNamed('file'),
          ),
        ).thenAnswer((_) async => 'https://example.com/image.jpg');
        when(
          mockAuthRepository.updateUser(any),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        await controller.updateProfileImage(
          file: mockFile,
          currentUser: testUser,
        );

        // Assert
        verify(
          mockAnalyticsService.logProfileEdit(userId: testUser.uid),
        ).called(1);
      });

      test(
        'should set state to AsyncData(null) on successful image update',
        () async {
          // Arrange
          when(
            mockContentModerationService.validateImage(any),
          ).thenAnswer((_) async => true);
          when(
            mockStorageRepository.uploadProfileImage(
              userId: anyNamed('userId'),
              file: anyNamed('file'),
            ),
          ).thenAnswer((_) async => 'https://example.com/image.jpg');
          when(
            mockAuthRepository.updateUser(any),
          ).thenAnswer((_) async => const Right(unit));

          final controller = container.read(profileControllerProvider.notifier);

          // Act
          await controller.updateProfileImage(
            file: mockFile,
            currentUser: testUser,
          );

          // Assert
          final state = container.read(profileControllerProvider);
          expect(state.hasValue, true);
          expect((state as AsyncData).value, null);
        },
      );

      test(
        'should set state to AsyncError when image validation fails',
        () async {
          // Arrange
          final validationException = Exception(
            'Image contains inappropriate content',
          );
          when(
            mockContentModerationService.validateImage(any),
          ).thenThrow(validationException);

          final controller = container.read(profileControllerProvider.notifier);

          // Act & Assert
          await expectLater(
            () => controller.updateProfileImage(
              file: mockFile,
              currentUser: testUser,
            ),
            throwsA(isA<Exception>()),
          );

          // Assert state
          final state = container.read(profileControllerProvider);
          expect(state.hasError, true);
        },
      );

      test('should set state to AsyncError when upload fails', () async {
        // Arrange
        when(
          mockContentModerationService.validateImage(any),
        ).thenAnswer((_) async => true);
        when(
          mockStorageRepository.uploadProfileImage(
            userId: anyNamed('userId'),
            file: anyNamed('file'),
          ),
        ).thenThrow(Exception('Upload failed'));

        final controller = container.read(profileControllerProvider.notifier);

        // Act & Assert
        await expectLater(
          () => controller.updateProfileImage(
            file: mockFile,
            currentUser: testUser,
          ),
          throwsA(isA<Exception>()),
        );

        // Assert state
        final state = container.read(profileControllerProvider);
        expect(state.hasError, true);
      });

      test('should set state to AsyncError when update user fails', () async {
        // Arrange
        when(
          mockContentModerationService.validateImage(any),
        ).thenAnswer((_) async => true);
        when(
          mockStorageRepository.uploadProfileImage(
            userId: anyNamed('userId'),
            file: anyNamed('file'),
          ),
        ).thenAnswer((_) async => 'https://example.com/image.jpg');
        when(
          mockAuthRepository.updateUser(any),
        ).thenThrow(Exception('Update failed'));

        final controller = container.read(profileControllerProvider.notifier);

        // Act & Assert
        await expectLater(
          () => controller.updateProfileImage(
            file: mockFile,
            currentUser: testUser,
          ),
          throwsA(isA<Exception>()),
        );

        // Assert state
        final state = container.read(profileControllerProvider);
        expect(state.hasError, true);
      });
    });

    group('deleteProfile', () {
      test('should set state to AsyncLoading when called', () async {
        // Arrange
        when(
          mockAuthRepository.deleteAccount(),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        final future = controller.deleteProfile();

        // Assert - verify loading state
        expect(container.read(profileControllerProvider).isLoading, true);

        // Wait for completion
        await future;
      });

      test('should call deleteAccount on repository', () async {
        // Arrange
        when(
          mockAuthRepository.deleteAccount(),
        ).thenAnswer((_) async => const Right(unit));

        final controller = container.read(profileControllerProvider.notifier);

        // Act
        await controller.deleteProfile();

        // Assert
        verify(mockAuthRepository.deleteAccount()).called(1);
      });

      test(
        'should set state to AsyncData(null) on successful deletion',
        () async {
          // Arrange
          when(
            mockAuthRepository.deleteAccount(),
          ).thenAnswer((_) async => const Right(unit));

          final controller = container.read(profileControllerProvider.notifier);

          // Act
          await controller.deleteProfile();

          // Assert
          final state = container.read(profileControllerProvider);
          expect(state.hasValue, true);
          expect((state as AsyncData).value, null);
        },
      );

      test('should set state to AsyncError on deletion failure', () async {
        // Arrange
        final error = Exception('Failed to delete account');
        when(mockAuthRepository.deleteAccount()).thenThrow(error);

        final controller = container.read(profileControllerProvider.notifier);

        // Act & Assert
        await expectLater(
          () => controller.deleteProfile(),
          throwsA(isA<Exception>()),
        );

        // Assert state
        final state = container.read(profileControllerProvider);
        expect(state.hasError, true);
      });
    });
  });
}
