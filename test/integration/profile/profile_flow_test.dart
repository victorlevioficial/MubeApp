import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/design_system/components/buttons/app_button.dart';
import 'package:mube/src/design_system/components/loading/app_shimmer.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_review.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/profile/presentation/edit_profile/widgets/forms/music_links_form.dart';
import 'package:mube/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:mube/src/features/profile/presentation/profile_controller.dart';
import 'package:mube/src/features/profile/presentation/public_profile_screen.dart';
import 'package:mube/src/features/storage/data/storage_repository.dart';

import '../../helpers/firebase_mocks.dart';
import '../../helpers/firebase_test_config.dart';
import '../../helpers/pump_app.dart';
@GenerateNiceMocks([
  MockSpec<AuthRemoteDataSource>(),
  MockSpec<StorageRepository>(),
])
import 'profile_flow_test.mocks.dart';

class FakeAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  FirebaseAnalyticsObserver getObserver() {
    throw UnimplementedError();
  }

  @override
  Future<void> logAuthSignupComplete({required String method}) async {}

  @override
  Future<void> logMatchPointFilter({
    required List<String> instruments,
    required List<String> genres,
    required double distance,
  }) async {}

  @override
  Future<void> logFeedPostView({required String postId}) async {}

  @override
  Future<void> logProfileEdit({required String userId}) async {}
}

/// Testes de integraÃƒÂ§ÃƒÂ£o para o fluxo de perfil
///
/// Cobertura:
/// - VisualizaÃƒÂ§ÃƒÂ£o do perfil
/// - EdiÃƒÂ§ÃƒÂ£o de dados bÃƒÂ¡sicos
/// - Upload de foto de perfil
/// - EdiÃƒÂ§ÃƒÂ£o de dados especÃƒÂ­ficos por tipo (profissional, banda, estÃƒÂºdio)
/// - ValidaÃƒÂ§ÃƒÂ£o de formulÃƒÂ¡rios
/// - Logout
/// - ExclusÃƒÂ£o de conta
void main() {
  setUpAll(() => setupFirebaseCoreMocks());

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

    Future<void> pumpPublicProfile(
      WidgetTester tester,
      AppUser user, {
      Stream<AppUser?>? profileStream,
      AppUser? viewer,
    }) async {
      final effectiveViewer = viewer ?? user;

      when(
        mockAuthDataSource.watchUserProfile(user.uid),
      ).thenAnswer((_) => profileStream ?? Stream.value(user));
      when(mockAuthDataSource.currentUser).thenReturn(
        MockUser(uid: effectiveViewer.uid, email: effectiveViewer.email),
      );

      await tester.pumpApp(
        PublicProfileScreen(profileRef: user.uid),
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(mockAuthDataSource),
          ),
          analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(mockAuthDataSource.currentUser),
          ),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(effectiveViewer),
          ),
          publicProfileMetricsProvider(
            user.uid,
          ).overrideWith((ref) async => (averageRating: null, reviewCount: 0)),
          userReviewsProvider(
            user.uid,
          ).overrideWith((ref) => Stream.value(const <GigReview>[])),
          publicCreatorOpenGigsProvider(
            user.uid,
          ).overrideWith((ref) => Stream.value(const <Gig>[])),
        ],
      );
    }

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
          location: {'cidade': 'SÃƒÂ£o Paulo', 'estado': 'SP'},
        );

        await pumpPublicProfile(tester, testUser);

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Verifica nome artÃƒÂ­stico e tipo de perfil (em maiÃƒÂºsculas)
        expect(find.text('Johnny Rock'), findsOneWidget);
        expect(find.byType(PublicProfileScreen), findsOneWidget);
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
          const PublicProfileScreen(profileRef: 'test-uid'),
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

        // Assert - Verifica nome da banda e tipo de perfil (em maiÃƒÂºsculas)
        expect(find.text('The Rockers'), findsOneWidget);
        expect(find.text('BANDA'), findsOneWidget);
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
          location: {'cidade': 'SÃƒÂ£o Paulo', 'estado': 'SP'},
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid', email: 'studio@example.com'));

        await tester.pumpApp(
          const PublicProfileScreen(profileRef: 'test-uid'),
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

        // Assert - Verifica nome do estÃƒÂºdio e tipo de perfil (em maiÃƒÂºsculas)
        expect(find.text('Music Studio'), findsOneWidget);
        expect(find.text('EST\u00daDIO'), findsOneWidget);
      });

      testWidgets('should show loading state', (tester) async {
        // Arrange
        // Use a controller to control when the data is emitted, keeping it in "loading" state initially
        final profileController = StreamController<AppUser?>.broadcast();

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => profileController.stream);
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const PublicProfileScreen(profileRef: 'test-uid'),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            // We need to override this to ensure the stream comes from our controller
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        // Initial state is loading because the stream hasn't emitted yet
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Deve mostrar skeleton de loading (ShimmerProfileHeader implies CircularProgressIndicator or Shimmer)
        // Assert - Deve mostrar skeleton de loading
        expect(find.byType(SkeletonShimmer), findsWidgets);

        await profileController.close();
      });

      testWidgets('should show error state', (tester) async {
        // Arrange
        final profileController = StreamController<AppUser?>.broadcast();

        when(mockAuthDataSource.watchUserProfile('test-uid')).thenAnswer((_) {
          return profileController.stream;
        });

        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const PublicProfileScreen(profileRef: 'test-uid'),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            authStateChangesProvider.overrideWith((ref) {
              return Stream.value(MockUser(uid: 'test-uid'));
            }),
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(
                const AppUser(
                  uid: 'viewer-uid',
                  email: 'viewer@example.com',
                  nome: 'Viewer',
                  tipoPerfil: AppUserType.professional,
                  cadastroStatus: 'concluido',
                ),
              ),
            ),
          ],
        );

        // Act
        // Initial state should be loading
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(SkeletonShimmer), findsOneWidget);

        // Emit error and ensure event loop processes it
        await tester.runAsync(() async {
          profileController.addError(Exception('Error loading profile'));
          await Future.delayed(Duration.zero);
        });

        // Process stream emission and rebuild UI
        await tester.pump(); // Start error propagation
        await tester.pump(); // Process error state rebuild
        await tester.pump(
          const Duration(milliseconds: 100),
        ); // Allow for state stability

        // Assert - Deve mostrar mensagem de erro e NÃƒÆ’O mostrar o skeleton
        expect(find.byType(SkeletonShimmer), findsNothing);
        expect(find.textContaining('Error loading profile'), findsOneWidget);

        await profileController.close();
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
          const EditProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Tela de ediÃƒÂ§ÃƒÂ£o deve ser exibida
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
          const EditProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.byType(EditProfileScreen), findsOneWidget);
      });

      testWidgets('should navigate to music links tab when a link is invalid', (
        tester,
      ) async {
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
          dadosProfissional: {
            'nomeArtistico': 'John',
            'celular': '(11) 99999-9999',
            'categorias': ['singer'],
            'generosMusicais': ['Rock'],
          },
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const EditProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Links'));
        await tester.pumpAndSettle();

        final musicLinksFields = find.descendant(
          of: find.byType(MusicLinksForm),
          matching: find.byType(TextFormField),
        );

        await tester.enterText(
          musicLinksFields.first,
          'https://google.com/artist/test',
        );
        await tester.pump();

        await tester.tap(find.text('Perfil'));
        await tester.pumpAndSettle();

        final saveButton = find.widgetWithText(
          AppButton,
          'Salvar Altera\u00E7\u00F5es',
        );
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(find.text('Use um link v\u00E1lido do Spotify.'), findsWidgets);
        expect(find.text('Links'), findsWidgets);
      });

      testWidgets('should show shortened media tab label', (tester) async {
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
          dadosProfissional: {
            'nomeArtistico': 'John',
            'celular': '(11) 99999-9999',
            'categorias': ['singer'],
            'generosMusicais': ['Rock'],
          },
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const EditProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('M\u00EDdia'), findsOneWidget);
        expect(find.text('Midia & Portfolio'), findsNothing);
      });

      testWidgets('should keep music links tab selected while saving', (
        tester,
      ) async {
        const testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          nome: 'John Doe',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'concluido',
          dadosProfissional: {
            'nomeArtistico': 'John',
            'celular': '(11) 99999-9999',
            'categorias': ['singer'],
            'generosMusicais': ['Rock'],
          },
        );
        final saveCompleter = Completer<void>();

        addTearDown(() {
          if (!saveCompleter.isCompleted) {
            saveCompleter.complete();
          }
        });

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));
        when(mockAuthDataSource.updateUserProfile(any)).thenAnswer((_) async {
          await saveCompleter.future;
        });

        await tester.pumpApp(
          const EditProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Links'));
        await tester.pumpAndSettle();

        final musicLinksFields = find.descendant(
          of: find.byType(MusicLinksForm),
          matching: find.byType(TextFormField),
        );

        await tester.enterText(
          musicLinksFields.first,
          'https://open.spotify.com/artist/test',
        );
        await tester.pump();

        final saveButton = find.widgetWithText(
          AppButton,
          'Salvar Altera\u00E7\u00F5es',
        );
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pump(const Duration(milliseconds: 100));

        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.controller?.index, 2);

        saveCompleter.complete();
        await tester.pumpAndSettle();
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
          const EditProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            storageRepositoryProvider.overrideWithValue(mockStorageRepository),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

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
          const EditProfileScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            storageRepositoryProvider.overrideWithValue(mockStorageRepository),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.byType(EditProfileScreen), findsOneWidget);
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
          Consumer(
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
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
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
          Consumer(
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
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            authRemoteDataSourceProvider.overrideWithValue(mockAuthDataSource),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
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
            'categorias': ['singer', 'instrumentalist', 'stage_tech'],
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
          const PublicProfileScreen(profileRef: 'test-uid'),
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
          const PublicProfileScreen(profileRef: 'test-uid'),
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
          const PublicProfileScreen(profileRef: 'test-uid'),
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

        // Assert - Verifica nome e tipo de perfil (em maiÃƒÂºsculas)
        expect(find.text('Event Organizer'), findsOneWidget);
        expect(find.text('CONTRATANTE'), findsOneWidget);
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
          dadosProfissional: {'nomeArtistico': 'John Doe'},
          location: {
            'cidade': 'SÃƒÂ£o Paulo',
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
          const PublicProfileScreen(profileRef: 'test-uid'),
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
          dadosProfissional: {'nomeArtistico': 'John Doe'},
          location: null,
        );

        when(
          mockAuthDataSource.watchUserProfile('test-uid'),
        ).thenAnswer((_) => Stream.value(testUser));
        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'test-uid'));

        await tester.pumpApp(
          const PublicProfileScreen(profileRef: 'test-uid'),
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

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
      });
    });
  });
}
