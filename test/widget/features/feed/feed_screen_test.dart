import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/design_system/components/feedback/empty_state_widget.dart';
import 'package:mube/src/design_system/components/loading/app_skeleton.dart'
    show SkeletonShimmer;
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/paginated_feed_response.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:mube/src/features/feed/presentation/feed_screen.dart';
import 'package:mube/src/features/feed/presentation/widgets/featured_spotlight_carousel.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_skeleton.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/matchpoint/presentation/widgets/matchpoint_highlight_card.dart';
import 'package:mube/src/features/notifications/data/notification_repository.dart';
import 'package:mube/src/routing/route_paths.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../helpers/test_fakes.dart';

void main() {
  late FakeFeedImagePrecacheService fakePrecacheService;
  late FakeFavoriteRepository fakeFavoriteRepository;
  late FakeFeedRepository fakeFeedRepository;
  late FakeAuthRepository fakeAuthRepository;
  late FakeFirebaseUser fakeUser;
  late FakeNotificationRepository fakeNotificationRepository;

  setUp(() {
    fakePrecacheService = FakeFeedImagePrecacheService();
    fakeFavoriteRepository = FakeFavoriteRepository();
    fakeFeedRepository = FakeFeedRepository();
    fakeAuthRepository = FakeAuthRepository();
    fakeUser = FakeFirebaseUser();
    fakeNotificationRepository = FakeNotificationRepository();

    fakeAuthRepository.appUser = const AppUser(
      uid: 'test-user-id',
      nome: 'Test User',
      email: 'test@example.com',
      location: {'lat': -23.5505, 'lng': -46.6333},
    );

    fakeAuthRepository.emitUser(fakeUser);
  });

  Widget createSubject({
    AsyncValue<AppUser?>? userState,
    List<dynamic> additionalOverrides = const [],
  }) {
    const defaultUser = AppUser(
      uid: 'test-user-id',
      nome: 'Test User',
      email: 'test@example.com',
      location: {'lat': -23.5505, 'lng': -46.6333},
    );

    return ProviderScope(
      overrides: [
        favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepository),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepository),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        authStateChangesProvider.overrideWith((ref) => Stream.value(fakeUser)),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(userState?.value ?? defaultUser),
        ),
        feedImagePrecacheServiceProvider.overrideWithValue(fakePrecacheService),
        notificationRepositoryProvider.overrideWithValue(
          fakeNotificationRepository,
        ),
        ...additionalOverrides,
      ],
      child: const MaterialApp(home: FeedScreen()),
    );
  }

  Widget createRoutedSubject({
    required AppUser user,
    List<dynamic> additionalOverrides = const [],
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
        GoRoute(
          path: RoutePaths.matchpoint,
          builder: (context, state) =>
              const Scaffold(body: Text('Matchpoint Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepository),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepository),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        authStateChangesProvider.overrideWith((ref) => Stream.value(fakeUser)),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        feedImagePrecacheServiceProvider.overrideWithValue(fakePrecacheService),
        notificationRepositoryProvider.overrideWithValue(
          fakeNotificationRepository,
        ),
        ...additionalOverrides,
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('FeedScreen', () {
    testWidgets('shows full screen skeleton when loading', (tester) async {
      // Setup the completer to hang the repository request
      fakeFeedRepository.requestCompleter = Completer<void>();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject());
        // First pump renders initial frame
        await tester.pump();
        // Second pump processes addPostFrameCallback where loadAllData is called
        await tester.pump();
      });

      expect(find.byType(FeedScreenSkeleton), findsOneWidget);

      // Clean up the completer so the test can finish without unresolved promises
      fakeFeedRepository.requestCompleter!.complete();
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('shows error state when feed fails', (tester) async {
      fakeFeedRepository.throwError = true;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject());
        // Trigger loadAllData
        await tester.pump();
        // Allow error propagation
        await tester.pumpAndSettle(const Duration(seconds: 2));
      });

      expect(find.text('Nao foi possivel carregar o feed'), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('allows pull-to-refresh recovery from error state', (
      tester,
    ) async {
      fakeFeedRepository.throwError = true;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      });

      expect(find.text('Nao foi possivel carregar o feed'), findsOneWidget);

      fakeFeedRepository.throwError = false;

      await mockNetworkImagesFor(() async {
        await tester.drag(find.byType(ListView), const Offset(0, 300));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      });

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('Nao foi possivel carregar o feed'), findsNothing);
    });

    testWidgets('shows empty state when no users found', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject());
        // Trigger loadAllData
        await tester.pump();
        // Allow data loading to complete (fake repo returns empty list by default)
        await tester.pumpAndSettle(const Duration(seconds: 2));
      });

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });

    testWidgets('shows gigs preview section on home when gigs exist', (
      tester,
    ) async {
      final previewGig = Gig(
        id: 'gig-preview-1',
        title: 'Baterista para show pop',
        description:
            'Set de 90 minutos com repertorio nacional e internacional.',
        gigType: GigType.liveShow,
        status: GigStatus.open,
        dateMode: GigDateMode.fixedDate,
        gigDate: DateTime(2026, 4, 12, 20),
        locationType: GigLocationType.onsite,
        location: const {'label': 'Sao Paulo, SP'},
        genres: const ['Pop'],
        requiredInstruments: const ['Bateria'],
        requiredCrewRoles: const [],
        requiredStudioServices: const [],
        slotsTotal: 2,
        slotsFilled: 1,
        compensationType: CompensationType.fixed,
        compensationValue: 600,
        creatorId: 'creator-1',
        applicantCount: 1,
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createSubject(
            additionalOverrides: [
              homeGigsPreviewProvider.overrideWith(
                (ref) => Stream.value([previewGig]),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      });

      expect(find.text('Gigs em aberto'), findsOneWidget);
      expect(find.text('Baterista para show pop'), findsOneWidget);
      expect(find.text('Ver todos'), findsOneWidget);
    });

    testWidgets('shows public contractor section on home when venues exist', (
      tester,
    ) async {
      fakeFeedRepository.venues = const [
        FeedItem(
          uid: 'venue-1',
          nome: 'Casa Azul',
          nomeArtistico: 'Casa Azul',
          tipoPerfil: 'contratante',
          distanceKm: 2,
        ),
      ];

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject());
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      });

      await tester.scrollUntilVisible(
        find.text('Locais pr\u00F3ximos'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Locais pr\u00F3ximos'), findsOneWidget);
      expect(find.text('Casa Azul'), findsWidgets);
    });

    testWidgets('renders matchpoint highlight below gigs preview', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const previewGig = Gig(
        id: 'gig-preview-2',
        title: 'Baixista para festival',
        description: 'Repertorio autoral com ensaio fechado para abril.',
        gigType: GigType.liveShow,
        status: GigStatus.open,
        dateMode: GigDateMode.toBeArranged,
        locationType: GigLocationType.onsite,
        genres: ['Indie'],
        requiredInstruments: ['Baixo'],
        requiredCrewRoles: [],
        requiredStudioServices: [],
        slotsTotal: 1,
        slotsFilled: 0,
        compensationType: CompensationType.negotiable,
        creatorId: 'creator-1',
      );

      const user = AppUser(
        uid: 'test-user-id',
        nome: 'Test User',
        email: 'test@example.com',
        tipoPerfil: AppUserType.professional,
        dadosProfissional: {
          'categorias': ['singer'],
        },
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createSubject(
            userState: const AsyncData(user),
            additionalOverrides: [
              homeGigsPreviewProvider.overrideWith(
                (ref) => Stream.value([previewGig]),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      });

      final gigsTop = tester.getTopLeft(find.text('Gigs em aberto')).dy;
      final matchpointTop = tester
          .getTopLeft(find.byType(MatchpointHighlightCard))
          .dy;

      expect(find.byType(MatchpointHighlightCard), findsOneWidget);
      expect(matchpointTop, greaterThan(gigsTop));
    });

    testWidgets('shows only spotlight profiles with avatar photo', (
      tester,
    ) async {
      fakeFeedRepository.discoverFeedPool = const [
        FeedItem(
          uid: 'with-avatar',
          nome: 'With Avatar',
          nomeArtistico: 'Com Avatar',
          foto: 'https://example.com/with-avatar.jpg',
          tipoPerfil: 'profissional',
        ),
        FeedItem(
          uid: 'without-avatar',
          nome: 'Without Avatar',
          nomeArtistico: 'Sem Avatar',
          tipoPerfil: 'profissional',
        ),
      ];

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      });

      final spotlightCarousel = find.byType(FeaturedSpotlightCarousel);

      expect(spotlightCarousel, findsOneWidget);
      expect(
        find.descendant(
          of: spotlightCarousel,
          matching: find.text('Com Avatar'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: spotlightCarousel,
          matching: find.text('Sem Avatar'),
        ),
        findsNothing,
      );
    });

    testWidgets('navigates to matchpoint from feed highlight card', (
      tester,
    ) async {
      const user = AppUser(
        uid: 'test-user-id',
        nome: 'Test User',
        email: 'test@example.com',
        tipoPerfil: AppUserType.professional,
        dadosProfissional: {
          'categorias': ['singer'],
        },
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createRoutedSubject(
            user: user,
            additionalOverrides: [
              homeGigsPreviewProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      });

      await tester.scrollUntilVisible(
        find.text('Ativar MatchPoint'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ativar MatchPoint'));
      await tester.pumpAndSettle();

      expect(find.text('Matchpoint Screen'), findsOneWidget);
    });

    testWidgets(
      'does not keep full screen skeleton while gigs preview resolves on first render',
      (tester) async {
        final gigsPreviewController = StreamController<List<Gig>>();
        addTearDown(gigsPreviewController.close);

        fakeFeedRepository.mainFeedResponse = const PaginatedFeedResponse(
          items: [
            FeedItem(
              uid: 'artist-1',
              nome: 'Artist One',
              nomeArtistico: 'Artist One',
              tipoPerfil: 'profissional',
            ),
          ],
          hasMore: false,
          lastDocument: null,
        );

        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            createSubject(
              additionalOverrides: [
                homeGigsPreviewProvider.overrideWith(
                  (ref) => gigsPreviewController.stream,
                ),
              ],
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        });

        expect(find.byType(FeedScreenSkeleton), findsNothing);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.text('Gigs em aberto'), findsOneWidget);
        expect(find.byType(SkeletonShimmer), findsOneWidget);

        gigsPreviewController.add(const []);
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(CustomScrollView), findsOneWidget);
      },
    );

    testWidgets(
      'does not keep skeleton visible while critical image warmup is still running',
      (tester) async {
        fakePrecacheService.criticalUrlsCompleter = Completer<void>();
        fakeFeedRepository.discoverFeedPool = const [
          FeedItem(
            uid: 'artist-1',
            nome: 'Artist One',
            nomeArtistico: 'Artist One',
            tipoPerfil: 'profissional',
            foto: 'https://example.com/artist-1.jpg',
          ),
        ];

        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            createSubject(
              additionalOverrides: [
                homeGigsPreviewProvider.overrideWith(
                  (ref) => Stream.value(const []),
                ),
              ],
            ),
          );
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        });

        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(FeedScreenSkeleton), findsNothing);
        expect(fakePrecacheService.criticalUrlsHistory, isNotEmpty);

        fakePrecacheService.criticalUrlsCompleter!.complete();
        await tester.pump();
      },
    );
  });
}
