import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/core/mixins/pagination_mixin.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:mube/src/features/search/presentation/search_controller.dart';
import 'package:mube/src/features/search/presentation/search_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeFeedImagePrecacheService fakePrecacheService;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakePrecacheService = FakeFeedImagePrecacheService();
  });

  Widget createSubject({
    SearchPaginationState? searchState,
    AsyncValue<List<FeedItem>>? asyncValue,
  }) {
    final user = TestData.user(uid: 'user-1');
    fakeAuthRepo.appUser = user;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SearchScreen()),
        GoRoute(
          path: '/user/:id',
          builder: (context, state) => Scaffold(
            body: Text('User Profile: ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        feedImagePrecacheServiceProvider.overrideWithValue(fakePrecacheService),
        searchControllerProvider.overrideWith(() {
          return FakeSearchController(
            state: searchState,
            asyncValue: asyncValue,
          );
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SearchScreen', () {
    testWidgets('renders app bar and search field', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('Busca'), findsOneWidget);
      expect(find.text('Buscar por nome...'), findsOneWidget);
    });

    testWidgets('renders category tabs', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Verifica se o CustomScrollView foi renderizado (contém as tabs)
      expect(find.byType(CustomScrollView), findsOneWidget);
      // Verifica título da busca
      expect(find.text('Busca'), findsOneWidget);
    });

    testWidgets('renders empty state when no results', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
      expect(find.text('Tente ajustar os filtros'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('renders results list with FeedCardVertical', (tester) async {
      final feedItems = [
        TestData.feedItem(id: 'user-1', nome: 'Musician 1'),
        TestData.feedItem(id: 'user-2', nome: 'Band 1'),
      ];

      await tester.pumpWidget(
        createSubject(
          searchState: SearchPaginationState(
            items: feedItems,
            status: PaginationStatus.loaded,
            hasMore: false,
          ),
          asyncValue: AsyncValue.data(feedItems),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Musician 1'), findsOneWidget);
      expect(find.text('Band 1'), findsOneWidget);
    });

    testWidgets('renders loading skeletons during loading', (tester) async {
      await tester.pumpWidget(
        createSubject(
          searchState: const SearchPaginationState(
            status: PaginationStatus.loading,
            hasMore: true,
          ),
          asyncValue: const AsyncValue.loading(),
        ),
      );
      await tester.pump();

      // Deve mostrar o CustomScrollView durante loading
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        createSubject(
          searchState: const SearchPaginationState(
            status: PaginationStatus.error,
            errorMessage: 'Erro ao buscar',
            hasMore: false,
          ),
          asyncValue: AsyncValue.error('Erro ao buscar', StackTrace.current),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verifica se o ícone de erro está presente (o texto pode aparecer em mais de um lugar)
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Erro ao buscar'), findsWidgets);
    });

    testWidgets('renders filter button', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('navigates to profile when result tapped', (tester) async {
      final feedItems = [TestData.feedItem(id: 'user-123', nome: 'Test User')];

      await tester.pumpWidget(
        createSubject(
          searchState: SearchPaginationState(
            items: feedItems,
            status: PaginationStatus.loaded,
            hasMore: false,
          ),
          asyncValue: AsyncValue.data(feedItems),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Test User'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('User Profile: user-123'), findsOneWidget);
    });
  });
}
