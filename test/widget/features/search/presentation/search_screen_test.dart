import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/core/mixins/pagination_mixin.dart';
import 'package:mube/src/design_system/foundations/tokens/app_assets.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:mube/src/features/search/domain/search_filters.dart';
import 'package:mube/src/features/search/presentation/search_controller.dart';
import 'package:mube/src/features/search/presentation/search_screen.dart';
import 'package:mube/src/features/search/presentation/widgets/active_filters_bar.dart';
import 'package:mube/src/features/search/presentation/widgets/smart_prefilter_grid.dart';
import 'package:mube/src/utils/professional_profile_utils.dart';

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
      expect(find.text('Buscar musicos, bandas, estudios...'), findsOneWidget);
    });

    testWidgets('renders discovery state by default', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('Busca'), findsOneWidget);
      expect(find.byType(SmartPrefilterGrid), findsOneWidget);
    });

    testWidgets('renders context-aware discovery icons', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byIcon(FontAwesomeIcons.microphone), findsOneWidget);
      expect(find.byIcon(FontAwesomeIcons.guitar), findsAtLeastNWidgets(2));
      expect(find.byIcon(FontAwesomeIcons.drum), findsOneWidget);
      expect(find.byIcon(FontAwesomeIcons.compactDisc), findsOneWidget);
      expect(find.byIcon(FontAwesomeIcons.volumeHigh), findsAtLeastNWidgets(2));
      expect(find.byIcon(FontAwesomeIcons.toolbox), findsAtLeastNWidgets(1));
      expect(find.byIcon(FontAwesomeIcons.hatCowboy), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader.toString().contains(
                AppAssets.searchPrefilterKeyboardSvg,
              ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders empty state when no results', (tester) async {
      await tester.pumpWidget(
        createSubject(
          searchState: const SearchPaginationState(
            filters: SearchFilters(term: 'rock'),
            status: PaginationStatus.loaded,
            hasMore: false,
          ),
          asyncValue: const AsyncValue.data([]),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
      expect(
        find.text('Tente ajustar os filtros ou buscar por outros termos'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('renders results list with FeedCardVertical', (tester) async {
      const feedItems = [
        FeedItem(
          uid: 'user-1',
          nome: 'Musician 1',
          nomeArtistico: 'Musician 1',
          tipoPerfil: 'profissional',
        ),
        FeedItem(
          uid: 'user-2',
          nome: 'Band 1',
          nomeArtistico: 'Band 1',
          tipoPerfil: 'banda',
        ),
      ];

      await tester.pumpWidget(
        createSubject(
          searchState: const SearchPaginationState(
            filters: SearchFilters(term: 'rock'),
            items: feedItems,
            status: PaginationStatus.loaded,
            hasMore: false,
          ),
          asyncValue: const AsyncValue.data(feedItems),
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
            filters: SearchFilters(term: 'rock'),
            status: PaginationStatus.loading,
            hasMore: true,
          ),
          asyncValue: const AsyncValue.loading(),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        createSubject(
          searchState: const SearchPaginationState(
            filters: SearchFilters(term: 'rock'),
            status: PaginationStatus.error,
            errorMessage: 'Erro ao buscar',
            hasMore: false,
          ),
          asyncValue: AsyncValue.error('Erro ao buscar', StackTrace.current),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.textContaining('Erro ao buscar'), findsWidgets);
    });

    testWidgets('renders filter button', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byIcon(Icons.tune_rounded), findsWidgets);
    });

    testWidgets('renders remote recording active filter chip', (tester) async {
      const feedItems = [
        FeedItem(
          uid: 'producer-1',
          nome: 'Produtor 1',
          nomeArtistico: 'Produtor 1',
          tipoPerfil: 'profissional',
          offersRemoteRecording: true,
        ),
      ];

      await tester.pumpWidget(
        createSubject(
          searchState: const SearchPaginationState(
            filters: SearchFilters(
              term: 'producao',
              category: SearchCategory.professionals,
              professionalSubcategory: ProfessionalSubcategory.production,
              offersRemoteRecording: true,
            ),
            items: feedItems,
            status: PaginationStatus.loaded,
            hasMore: false,
          ),
          asyncValue: const AsyncValue.data(feedItems),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: find.byType(ActiveFiltersBar),
          matching: find.text(professionalRemoteRecordingLabel),
        ),
        findsOneWidget,
      );
    });

    testWidgets('navigates to profile when result tapped', (tester) async {
      const feedItems = [
        FeedItem(
          uid: 'user-123',
          nome: 'Test User',
          nomeArtistico: 'Test User',
          tipoPerfil: 'profissional',
        ),
      ];

      await tester.pumpWidget(
        createSubject(
          searchState: const SearchPaginationState(
            filters: SearchFilters(term: 'rock'),
            items: feedItems,
            status: PaginationStatus.loaded,
            hasMore: false,
          ),
          asyncValue: const AsyncValue.data(feedItems),
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
