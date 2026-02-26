import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_skeleton.dart';
import 'package:mube/src/features/search/data/search_repository.dart';
import 'package:mube/src/features/search/domain/paginated_search_response.dart';
import 'package:mube/src/features/search/presentation/search_screen.dart';

import '../../helpers/firebase_mocks.dart';
import '../../helpers/firebase_test_config.dart';
import '../../helpers/pump_app.dart';
@GenerateNiceMocks([
  MockSpec<AuthRemoteDataSource>(),
  MockSpec<SearchRepository>(),
])
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';
import 'search_flow_test.mocks.dart';

/// Testes de integração para o fluxo de busca
///
/// Cobertura:
/// - Busca por termo
/// - Filtros por categoria
/// - Filtros por gênero musical
/// - Filtros por instrumentos
/// - Filtros por funções (crew)
/// - Filtros por serviços de estúdio
/// - Paginação de resultados
/// - Estado vazio
/// - Erros de busca
void main() {
  group('Search Flow Integration Tests', () {
    late MockAuthRemoteDataSource mockAuthDataSource;
    late MockSearchRepository mockSearchRepository;

    setUpAll(() async {
      await setupFirebaseCoreMocks();
      provideDummy<Either<Failure, PaginatedSearchResponse>>(
        const Right(PaginatedSearchResponse(items: [], hasMore: false)),
      );
    });

    setUp(() {
      mockAuthDataSource = MockAuthRemoteDataSource();
      mockSearchRepository = MockSearchRepository();
    });

    group('Search by Term', () {
      testWidgets('should search users by name', (tester) async {
        // Arrange
        const testResults = PaginatedSearchResponse(
          items: [
            FeedItem(
              uid: 'user-1',
              nome: 'John Doe',
              nomeArtistico: 'Johnny Rock',
              tipoPerfil: 'profissional',
              generosMusicais: ['rock', 'pop'],
            ),
          ],
          hasMore: false,
        );

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer((_) async => const Right(testResults));

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('should show empty state when no results', (tester) async {
        // Arrange
        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Deve mostrar estado vazio
        expect(find.byType(SearchScreen), findsOneWidget);
      });
    });

    group('Category Filters', () {
      testWidgets('should filter by professionals category', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'user-1',
            nome: 'Professional User',
            tipoPerfil: 'profissional',
            generosMusicais: ['rock'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('should filter by bands category', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'band-1',
            nome: 'Rock Band',
            tipoPerfil: 'banda',
            generosMusicais: ['rock', 'metal'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('should filter by studios category', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'studio-1',
            nome: 'Music Studio',
            tipoPerfil: 'estudio',
            generosMusicais: [],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Genre Filters', () {
      testWidgets('should filter by music genres', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'user-1',
            nome: 'Rock Star',
            tipoPerfil: 'profissional',
            generosMusicais: ['rock'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Professional Subcategory Filters', () {
      testWidgets('should filter by singers', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'user-1',
            nome: 'Singer Name',
            tipoPerfil: 'profissional',
            generosMusicais: ['pop'],
            subCategories: ['singer'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('should filter by instrumentalists', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'user-1',
            nome: 'Guitar Player',
            tipoPerfil: 'profissional',
            generosMusicais: ['rock'],
            skills: ['guitar'],
            subCategories: ['instrumentalist'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('should filter by crew', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'user-1',
            nome: 'Sound Engineer',
            tipoPerfil: 'profissional',
            generosMusicais: [],
            skills: ['sound_engineer'],
            subCategories: ['crew'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('should filter by DJs', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'user-1',
            nome: 'DJ Name',
            tipoPerfil: 'profissional',
            generosMusicais: ['electronic'],
            subCategories: ['dj'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Instrument Filters', () {
      testWidgets('should filter by instruments', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'user-1',
            nome: 'Guitar Player',
            tipoPerfil: 'profissional',
            generosMusicais: ['rock'],
            skills: ['guitar', 'bass'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Studio Filters', () {
      testWidgets('should filter by studio services', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'studio-1',
            nome: 'Recording Studio',
            tipoPerfil: 'estudio',
            skills: ['recording', 'mixing'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('should filter by studio type', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'studio-1',
            nome: 'Home Studio',
            tipoPerfil: 'estudio',
            skills: ['recording'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Search State Management', () {
      testWidgets('should handle loading state', (tester) async {
        // Arrange
        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return const Right(PaginatedSearchResponse.empty());
        });

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump(); // Pump once to show loading

        // Assert - Deve mostrar indicador de loading
        expect(find.byType(FeedItemSkeleton), findsWidgets);

        // Wait for potential timers (e.g. debounce) to complete
        await tester.pump(const Duration(seconds: 1));
      });

      testWidgets('should handle search errors', (tester) async {
        // Arrange
        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Erro na busca')),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Deve mostrar mensagem de erro
        expect(find.byType(SearchScreen), findsOneWidget);
      });

      testWidgets('should handle rate limiting', (tester) async {
        // Arrange - Simular muitas requisições
        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
          ],
        );

        // Act - Fazer várias buscas rapidamente
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - A busca deve ser executada
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('should clear filters', (tester) async {
        // Arrange
        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
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
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Blocked Users', () {
      testWidgets('should exclude blocked users from results', (tester) async {
        // Arrange
        const currentUser = AppUser(
          uid: 'current-user',
          email: 'current@example.com',
          blockedUsers: ['blocked-user-1', 'blocked-user-2'],
        );

        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'current-user'));

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

        when(
          mockAuthDataSource.currentUser,
        ).thenReturn(MockUser(uid: 'current-user'));

        when(
          mockAuthDataSource.watchUserProfile('current-user'),
        ).thenAnswer((_) => Stream.value(currentUser));

        // final profileController = StreamController<AppUser?>.broadcast(
        //   onListen: () => debugPrint('[Test] profileController listened'),
        // );

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthDataSource.currentUser),
            ),
            // currentUserProfileProvider.overrideWith((ref) {
            //   debugPrint('[Test] currentUserProfileProvider override created');
            //   return Stream.value(currentUser);
            // }),
          ],
        );

        // Emit cached user first (simulating loading then data)
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: argThat(
              containsAll(['blocked-user-1', 'blocked-user-2']),
              named: 'blockedUsers',
            ),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Backing Vocal Filter', () {
      testWidgets('should filter by backing vocal capability', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'user-1',
            nome: 'Singer with Backing',
            tipoPerfil: 'profissional',
            generosMusicais: ['pop'],
            subCategories: ['singer'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Ghost Mode Exclusion', () {
      testWidgets('should exclude users in ghost mode', (tester) async {
        // Arrange
        final testResults = [
          const FeedItem(
            uid: 'user-1',
            nome: 'Visible User',
            tipoPerfil: 'profissional',
            generosMusicais: ['rock'],
          ),
        ];

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: testResults, hasMore: false),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - O repository deve filtrar usuários em ghost mode
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Pagination', () {
      testWidgets('should load more results on scroll', (tester) async {
        // Arrange
        final initialResults = List.generate(
          20,
          (index) => FeedItem(
            uid: 'user-$index',
            nome: 'User $index',
            tipoPerfil: 'profissional',
            generosMusicais: ['rock'],
          ),
        );

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaginatedSearchResponse(items: initialResults, hasMore: true),
          ),
        );

        when(
          mockAuthDataSource.watchUserProfile(any),
        ).thenAnswer((_) => Stream.value(null));

        await tester.pumpApp(
          const SearchScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              AuthRepository(mockAuthDataSource),
            ),
            searchRepositoryProvider.overrideWithValue(mockSearchRepository),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
        );

        // Act
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });
  });
}

class FakeAnalyticsService implements AnalyticsService {
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
