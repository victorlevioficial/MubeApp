import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/mixins/pagination_mixin.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_skeleton.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';
import 'package:mube/src/features/search/data/search_repository.dart';
import 'package:mube/src/features/search/domain/paginated_search_response.dart';
import 'package:mube/src/features/search/domain/search_filters.dart';
import 'package:mube/src/features/search/presentation/search_controller.dart';
import 'package:mube/src/features/search/presentation/search_screen.dart';
import 'package:mube/src/features/search/presentation/widgets/smart_prefilter_grid.dart';

import '../../helpers/firebase_mocks.dart';
import '../../helpers/firebase_test_config.dart';
import '../../helpers/pump_app.dart';

@GenerateNiceMocks([
  MockSpec<AuthRemoteDataSource>(),
  MockSpec<SearchRepository>(),
])
import 'search_flow_test.mocks.dart';

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

    Future<ProviderContainer> pumpSearchScreen(
      WidgetTester tester, {
      AppUser? currentUser,
      List<String> blockedUsers = const [],
    }) async {
      await tester.pumpApp(
        const SearchScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(mockAuthDataSource),
          ),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(currentUser),
          ),
          searchRepositoryProvider.overrideWithValue(mockSearchRepository),
          blockedUsersProvider.overrideWith(
            (ref) => Stream.value(blockedUsers),
          ),
          analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
        ],
      );
      await tester.pump();

      return ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)),
      );
    }

    Future<void> settleSearch(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }

    Future<void> runTermSearch(
      WidgetTester tester,
      ProviderContainer container,
      String term,
    ) async {
      container.read(searchControllerProvider.notifier).setTerm(term);
      await settleSearch(tester);
    }

    Future<void> applySearchFilters(
      WidgetTester tester,
      ProviderContainer container,
      SearchFilters filters,
    ) async {
      container.read(searchControllerProvider.notifier).applyFilters(filters);
      await settleSearch(tester);
    }

    VerificationResult verifySearchUsersCalled() {
      return verify(
        mockSearchRepository.searchUsers(
          filters: captureAnyNamed('filters'),
          startAfter: captureAnyNamed('startAfter'),
          requestId: anyNamed('requestId'),
          getCurrentRequestId: anyNamed('getCurrentRequestId'),
          blockedUsers: captureAnyNamed('blockedUsers'),
        ),
      );
    }

    testWidgets('starts in discovery mode by default', (tester) async {
      final container = await pumpSearchScreen(tester);

      expect(find.byType(SmartPrefilterGrid), findsOneWidget);
      expect(
        container.read(searchControllerProvider).status,
        PaginationStatus.initial,
      );
      verifyNever(
        mockSearchRepository.searchUsers(
          filters: anyNamed('filters'),
          startAfter: anyNamed('startAfter'),
          requestId: anyNamed('requestId'),
          getCurrentRequestId: anyNamed('getCurrentRequestId'),
          blockedUsers: anyNamed('blockedUsers'),
        ),
      );
    });

    testWidgets('searches by term and renders results', (tester) async {
      when(
        mockSearchRepository.searchUsers(
          filters: anyNamed('filters'),
          startAfter: anyNamed('startAfter'),
          requestId: anyNamed('requestId'),
          getCurrentRequestId: anyNamed('getCurrentRequestId'),
          blockedUsers: anyNamed('blockedUsers'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          PaginatedSearchResponse(
            items: [
              FeedItem(
                uid: 'user-1',
                nome: 'John Doe',
                nomeArtistico: 'Johnny Rock',
                tipoPerfil: 'profissional',
              ),
            ],
            hasMore: false,
          ),
        ),
      );

      final container = await pumpSearchScreen(tester);
      await runTermSearch(tester, container, 'john');

      expect(
        container.read(searchControllerProvider).items.map((item) => item.uid),
        ['user-1'],
      );
      final captured = verifySearchUsersCalled().captured;
      expect((captured[0] as SearchFilters).term, 'john');
    });

    testWidgets('shows empty state when no results are returned', (
      tester,
    ) async {
      when(
        mockSearchRepository.searchUsers(
          filters: anyNamed('filters'),
          startAfter: anyNamed('startAfter'),
          requestId: anyNamed('requestId'),
          getCurrentRequestId: anyNamed('getCurrentRequestId'),
          blockedUsers: anyNamed('blockedUsers'),
        ),
      ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

      final container = await pumpSearchScreen(tester);
      await runTermSearch(tester, container, 'sem resultado');

      expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
      expect(
        find.text('Tente ajustar os filtros ou buscar por outros termos'),
        findsOneWidget,
      );
    });

    testWidgets(
      'runs category-only searches for professionals, bands and studios',
      (tester) async {
        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

        final container = await pumpSearchScreen(tester);

        container
            .read(searchControllerProvider.notifier)
            .setCategory(SearchCategory.professionals);
        await settleSearch(tester);
        container
            .read(searchControllerProvider.notifier)
            .setCategory(SearchCategory.bands);
        await settleSearch(tester);
        container
            .read(searchControllerProvider.notifier)
            .setCategory(SearchCategory.studios);
        await settleSearch(tester);

        final captured = verifySearchUsersCalled().captured
            .whereType<SearchFilters>()
            .toList();
        expect(captured[0].category, SearchCategory.professionals);
        expect(captured[1].category, SearchCategory.bands);
        expect(captured.last.category, SearchCategory.studios);
      },
    );

    testWidgets(
      'applies professional and studio filters through applyFilters',
      (tester) async {
        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

        final container = await pumpSearchScreen(tester);

        await applySearchFilters(
          tester,
          container,
          const SearchFilters(
            professionalSubcategory: ProfessionalSubcategory.stageTech,
            genres: ['rock'],
            instruments: ['guitarra'],
            roles: ['Roadie'],
            canDoBackingVocal: true,
          ),
        );

        await applySearchFilters(
          tester,
          container,
          const SearchFilters(
            category: SearchCategory.studios,
            services: ['Gravacao'],
            studioType: 'home_studio',
          ),
        );

        final capturedFilters = verifySearchUsersCalled().captured
            .whereType<SearchFilters>()
            .toList();
        final professionalFilters = capturedFilters.first;

        expect(
          professionalFilters.professionalSubcategory,
          ProfessionalSubcategory.stageTech,
        );
        expect(professionalFilters.genres, ['rock']);
        expect(professionalFilters.instruments, ['guitarra']);
        expect(professionalFilters.roles, ['Roadie']);
        expect(professionalFilters.canDoBackingVocal, true);

        expect(
          capturedFilters.any(
            (filters) =>
                filters.category == SearchCategory.studios &&
                filters.services.contains('Gravacao') &&
                filters.studioType == 'home_studio',
          ),
          isTrue,
        );
      },
    );

    testWidgets('shows loading skeletons while a search is in flight', (
      tester,
    ) async {
      when(
        mockSearchRepository.searchUsers(
          filters: anyNamed('filters'),
          startAfter: anyNamed('startAfter'),
          requestId: anyNamed('requestId'),
          getCurrentRequestId: anyNamed('getCurrentRequestId'),
          blockedUsers: anyNamed('blockedUsers'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return const Right(PaginatedSearchResponse.empty());
      });

      final container = await pumpSearchScreen(tester);
      container.read(searchControllerProvider.notifier).setTerm('rock');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(FeedItemSkeleton), findsWidgets);

      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('shows error state when the repository fails', (tester) async {
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

      final container = await pumpSearchScreen(tester);
      await runTermSearch(tester, container, 'erro');

      expect(find.text('Erro ao buscar'), findsOneWidget);
      expect(find.textContaining('Erro na busca'), findsWidgets);
    });

    testWidgets('coalesces rapid term updates into a single debounced search', (
      tester,
    ) async {
      when(
        mockSearchRepository.searchUsers(
          filters: anyNamed('filters'),
          startAfter: anyNamed('startAfter'),
          requestId: anyNamed('requestId'),
          getCurrentRequestId: anyNamed('getCurrentRequestId'),
          blockedUsers: anyNamed('blockedUsers'),
        ),
      ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

      final container = await pumpSearchScreen(tester);
      final controller = container.read(searchControllerProvider.notifier);

      controller.setTerm('r');
      controller.setTerm('ro');
      controller.setTerm('rock');
      await settleSearch(tester);

      final verification = verifySearchUsersCalled();
      final captured = verification.captured;
      expect((captured[0] as SearchFilters).term, 'rock');
      verification.called(1);
    });

    testWidgets('reset returns the screen to discovery mode', (tester) async {
      when(
        mockSearchRepository.searchUsers(
          filters: anyNamed('filters'),
          startAfter: anyNamed('startAfter'),
          requestId: anyNamed('requestId'),
          getCurrentRequestId: anyNamed('getCurrentRequestId'),
          blockedUsers: anyNamed('blockedUsers'),
        ),
      ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

      final container = await pumpSearchScreen(tester);
      await applySearchFilters(
        tester,
        container,
        const SearchFilters(term: 'rock', genres: ['rock']),
      );

      container.read(searchControllerProvider.notifier).reset();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SmartPrefilterGrid), findsOneWidget);
      expect(
        container.read(searchControllerProvider).status,
        PaginationStatus.initial,
      );
    });

    testWidgets(
      'forwards blocked users from profile and stream to the repository',
      (tester) async {
        const currentUser = AppUser(
          uid: 'current-user',
          email: 'current@example.com',
          blockedUsers: ['blocked-user-1', 'blocked-user-2'],
        );

        when(
          mockSearchRepository.searchUsers(
            filters: anyNamed('filters'),
            startAfter: anyNamed('startAfter'),
            requestId: anyNamed('requestId'),
            getCurrentRequestId: anyNamed('getCurrentRequestId'),
            blockedUsers: anyNamed('blockedUsers'),
          ),
        ).thenAnswer((_) async => const Right(PaginatedSearchResponse.empty()));

        final container = await pumpSearchScreen(
          tester,
          currentUser: currentUser,
          blockedUsers: const ['blocked-stream-1'],
        );
        await runTermSearch(tester, container, 'rock');

        final captured = verifySearchUsersCalled().captured;
        expect(
          captured[2] as List<String>,
          containsAll(['blocked-user-1', 'blocked-user-2', 'blocked-stream-1']),
        );
      },
    );

    testWidgets('loads another page when pagination is requested', (
      tester,
    ) async {
      final cursor = MockDocumentSnapshot<Map<String, dynamic>>(
        id: 'cursor-1',
        data: const {'id': 'cursor-1'},
      );
      var calls = 0;

      when(
        mockSearchRepository.searchUsers(
          filters: anyNamed('filters'),
          startAfter: anyNamed('startAfter'),
          requestId: anyNamed('requestId'),
          getCurrentRequestId: anyNamed('getCurrentRequestId'),
          blockedUsers: anyNamed('blockedUsers'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          return Right(
            PaginatedSearchResponse(
              items: const [
                FeedItem(
                  uid: 'user-1',
                  nome: 'User 1',
                  tipoPerfil: 'profissional',
                ),
              ],
              hasMore: true,
              lastDocument: cursor,
            ),
          );
        }

        return const Right(
          PaginatedSearchResponse(
            items: [
              FeedItem(
                uid: 'user-2',
                nome: 'User 2',
                tipoPerfil: 'profissional',
              ),
            ],
            hasMore: false,
          ),
        );
      });

      final container = await pumpSearchScreen(tester);
      await runTermSearch(tester, container, 'rock');

      await container.read(searchControllerProvider.notifier).loadMore();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        container.read(searchControllerProvider).items.map((item) => item.uid),
        ['user-1', 'user-2'],
      );
      verifySearchUsersCalled().called(2);
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
