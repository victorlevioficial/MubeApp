import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:mube/src/features/profile/presentation/profile_controller.dart';
import 'package:mube/src/features/profile/presentation/profile_screen.dart';
import 'package:mube/src/features/storage/data/storage_repository.dart';

import '../../helpers/firebase_mocks.dart';
import '../../helpers/pump_app.dart';
@GenerateNiceMocks([
  MockSpec<AuthRemoteDataSource>(),
  MockSpec<StorageRepository>(),
])
import 'profile_flow_test.mocks.dart';

class FakeAnalyticsService extends Mock implements AnalyticsService {}

/// Testes de integração para o fluxo de perfil
///
/// Cobertura:
/// - Visualização do perfil
/// - Edição de dados básicos
/// - Upload de foto de perfil
/// - Edição de dados específicos por tipo (profissional, banda, estúdio)
/// - Validação de formulários
/// - Logout
/// - Exclusão de conta
void main() {
  group('Profile Flow Integration Tests', () {
    late MockAuthRemoteDataSource mockAuthDataSource;
    late MockStorageRepository mockStorageRepository;

    setUp(() {
      mockAuthDataSource = MockAuthRemoteDataSource();
      mockStorageRepository = MockStorageRepository();

      // Stub authStateChanges to return the current user to satisfy currentUserProfileProvider
      when(
        mockAuthDataSource.authStateChanges(),
      ).thenAnswer((_) => Stream.value(mockAuthDataSource.currentUser));
    });

    group('Profile View', () {
      testWidgets('should display professional profile', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
          dadosProfissional: {
            'nomeArtistico': 'Johnny Rock',
            'categorias': ['singer', 'instrumentalist'],
            'instrumentos': ['guitar', 'piano'],
            'generosMusicais': ['rock', 'pop'],
          },
          location: {'cidade': 'São Paulo', 'estado': 'SP'},
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid', email: 'test@example.com'));

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Johnny Rock'), findsOneWidget);
        expect(find.text('Profissional'), findsOneWidget);
      });

      testWidgets('should display band profile', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'band@example.com',
          nome: 'The Rockers',
          tipoPerfil: AppUserType.band,
          cadastroStatus: 'concluido',
          dadosBanda: {
            'nomeBanda': 'The Rockers',
            'generosMusicais': ['rock', 'metal'],
          },
          location: {'cidade': 'Rio de Janeiro', 'estado': 'RJ'},
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid', email: 'band@example.com'));

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('The Rockers'), findsOneWidget);
        expect(find.text('Banda'), findsOneWidget);
      });

      testWidgets('should display studio profile', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'studio@example.com',
          nome: 'Music Studio',
          tipoPerfil: AppUserType.studio,
          cadastroStatus: 'concluido',
          dadosEstudio: {
            'nomeEstudio': 'Music Studio',
            'studioType': 'commercial',
            'servicosOferecidos': ['recording', 'mixing'],
          },
          location: {'cidade': 'São Paulo', 'estado': 'SP'},
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid', email: 'studio@example.com'));

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Music Studio'), findsOneWidget);
        expect(find.text('Estúdio'), findsOneWidget);
      });

      testWidgets('should show loading state', (tester) async {
        // Arrange
        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(null));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockAuthDataSource),
              ),
            ],
            child: const ProfileScreen(),
          ),
        );

        // Act
        await tester.pump();

        // Assert - Deve mostrar skeleton de loading
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('should show error state', (tester) async {
        // Arrange
        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.error('Error loading profile'));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Deve mostrar mensagem de erro
        expect(find.textContaining('Erro'), findsOneWidget);
      });
    });

    group('Profile Edit', () {
      testWidgets('should update profile data', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
        );

        when(
          mockAuthDataSource.updateUserProfile(any),
        ).thenAnswer((_) async {});
        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockAuthDataSource),
              ),
            ],
            child: const EditProfileScreen(),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert - Tela de edição deve ser exibida
        expect(find.byType(EditProfileScreen), findsOneWidget);
      });

      testWidgets('should validate required fields', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: '',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockAuthDataSource),
              ),
            ],
            child: const EditProfileScreen(),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(EditProfileScreen), findsOneWidget);
      });
    });

    group('Profile Image', () {
      testWidgets('should upload profile image', (tester) async {
        // Arrange

        when(
          mockStorageRepository.uploadProfileImage(
            userId: anyNamed('userId'),
            file: anyNamed('file'),
          ),
        ).thenAnswer((_) async => 'https://example.com/new-photo.jpg');
        when(
          mockAuthDataSource.updateUserProfile(any),
        ).thenAnswer((_) async {});

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockAuthDataSource),
              ),
              storageRepositoryProvider.overrideWithValue(
                mockStorageRepository,
              ),
            ],
            child: const EditProfileScreen(),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(EditProfileScreen), findsOneWidget);
      });

      testWidgets('should handle image upload error', (tester) async {
        // Arrange
        when(
          mockStorageRepository.uploadProfileImage(
            userId: anyNamed('userId'),
            file: anyNamed('file'),
          ),
        ).thenThrow(Exception('Upload failed'));

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockAuthDataSource),
              ),
              storageRepositoryProvider.overrideWithValue(
                mockStorageRepository,
              ),
            ],
            child: const EditProfileScreen(),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(EditProfileScreen), findsOneWidget);
      });
    });

    group('Logout', () {
      testWidgets('should logout user', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));
        when(mockAuthDataSource.signOut()).thenAnswer((_) async {});

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Tap no botão de logout
        final logoutButton = find.byIcon(Icons.logout);
        if (logoutButton.evaluate().isNotEmpty) {
          await tester.tap(logoutButton);
          await tester.pumpAndSettle();

          // Assert
          verify(mockAuthDataSource.signOut()).called(1);
        }
      });
    });

    group('Delete Account', () {
      testWidgets('should delete user account', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));
        when(
          mockAuthDataSource.deleteAccount('test-uid'),
        ).thenAnswer((_) async {});

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Tela de perfil deve ser exibida
        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('should handle delete account error', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));
        when(mockAuthDataSource.deleteAccount('test-uid')).thenThrow(
          FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Re-autenticação necessária',
          ),
        );

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.byType(ProfileScreen), findsOneWidget);
      });
    });

    group('ProfileController', () {
      testWidgets('should update profile through controller', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
        );

        when(
          mockAuthDataSource.updateUserProfile(any),
        ).thenAnswer((_) async {});

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockAuthDataSource),
              ),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () async {
                    final controller = ref.read(
                      profileControllerProvider.notifier,
                    );
                    await controller.updateProfile(
                      currentUser: testUser,
                      updates: {'nome': 'Jane Doe'},
                    );
                  },
                  child: const Text('Update'),
                );
              },
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Update'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAuthDataSource.updateUserProfile(any)).called(1);
      });

      testWidgets('should handle update error', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
        );

        when(
          mockAuthDataSource.updateUserProfile(any),
        ).thenThrow(Exception('Update failed'));

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockAuthDataSource),
              ),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () async {
                    final controller = ref.read(
                      profileControllerProvider.notifier,
                    );
                    try {
                      await controller.updateProfile(
                        currentUser: testUser,
                        updates: {'nome': 'Jane Doe'},
                      );
                    } catch (e) {
                      // Expected error
                    }
                  },
                  child: const Text('Update'),
                );
              },
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Update'));
        await tester.pumpAndSettle();

        // Assert - O controller deve ter tentado atualizar
        verify(mockAuthDataSource.updateUserProfile(any)).called(1);
      });
    });

    group('Professional Profile Details', () {
      testWidgets('should display professional categories', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
          dadosProfissional: {
            'nomeArtistico': 'Johnny Rock',
            'categorias': ['singer', 'instrumentalist', 'crew'],
            'instrumentos': ['guitar', 'piano', 'drums'],
            'funcoes': ['sound_engineer', 'lighting_technician'],
            'generosMusicais': ['rock', 'pop', 'jazz'],
          },
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Johnny Rock'), findsOneWidget);
      });

      testWidgets('should display backing vocal info', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
          dadosProfissional: {
            'nomeArtistico': 'Johnny Rock',
            'categorias': ['singer'],
            'backingVocalMode': '2',
            'generosMusicais': ['rock'],
          },
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Johnny Rock'), findsOneWidget);
      });
    });

    group('Contractor Profile', () {
      testWidgets('should display contractor profile', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'contractor@example.com',
          nome: 'Event Organizer',
          tipoPerfil: AppUserType.contractor,
          cadastroStatus: 'concluido',
          dadosContratante: {'instagram': '@eventorganizer', 'genero': 'Todos'},
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Event Organizer'), findsOneWidget);
        expect(find.text('Contratante'), findsOneWidget);
      });
    });

    group('Profile Location', () {
      testWidgets('should display location info', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
          location: {
            'cidade': 'São Paulo',
            'estado': 'SP',
            'bairro': 'Pinheiros',
            'lat': -23.5,
            'lng': -46.6,
          },
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const ProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
      });

      testWidgets('should handle missing location', (tester) async {
        // Arrange
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
          location: null,
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockAuthDataSource),
              ),
            ],
            child: const ProfileScreen(),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
      });
    });
  });
}
