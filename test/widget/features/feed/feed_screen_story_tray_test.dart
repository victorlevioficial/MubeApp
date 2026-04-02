import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/bands/data/invites_repository.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/paginated_feed_response.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:mube/src/features/feed/presentation/feed_screen.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_header.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';
import 'package:mube/src/features/notifications/data/notification_repository.dart';
import 'package:mube/src/features/stories/domain/story_item.dart';
import 'package:mube/src/features/stories/domain/story_tray_bundle.dart';
import 'package:mube/src/features/stories/presentation/controllers/story_tray_controller.dart';
import 'package:mube/src/features/stories/presentation/widgets/story_tray.dart';
import 'package:mube/src/routing/route_paths.dart';

import '../../../helpers/test_fakes.dart';

List<StoryTrayBundle> _storyTrayBundles = const [];
List<StoryItem> _pendingStories = const [];
int _trackedStoryTrayRefreshCalls = 0;

class _StubStoryTrayController extends StoryTrayController {
  @override
  Future<List<StoryTrayBundle>> build() async => _storyTrayBundles;
}

class _TrackingStoryTrayController extends StoryTrayController {
  @override
  Future<List<StoryTrayBundle>> build() async => _storyTrayBundles;

  @override
  Future<void> refresh() async {
    _trackedStoryTrayRefreshCalls++;
    state = AsyncData(_storyTrayBundles);
  }
}

class _FailingStoryTrayController extends StoryTrayController {
  @override
  Future<List<StoryTrayBundle>> build() => Future<List<StoryTrayBundle>>.error(
    Exception('Erro ao carregar stories'),
  );
}

class _FakeInvitesRepository extends Fake implements InvitesRepository {
  @override
  Stream<List<Map<String, dynamic>>> getIncomingInvites(String uid) {
    return Stream.value(const []);
  }
}

StoryItem _storyItem({
  required String id,
  required String ownerUid,
  required String ownerName,
  required DateTime createdAt,
}) {
  return StoryItem(
    id: id,
    ownerUid: ownerUid,
    ownerName: ownerName,
    ownerType: 'profissional',
    mediaType: StoryMediaType.image,
    mediaUrl: 'https://example.com/$id.jpg',
    createdAt: createdAt,
    expiresAt: createdAt.add(const Duration(hours: 24)),
    status: StoryStatus.active,
  );
}

StoryTrayBundle _bundle({
  required String ownerUid,
  required String ownerName,
  required DateTime createdAt,
  bool isFavorite = false,
  bool isCurrentUser = false,
  bool hasUnseen = true,
}) {
  return StoryTrayBundle(
    ownerUid: ownerUid,
    ownerName: ownerName,
    ownerType: 'profissional',
    stories: [
      _storyItem(
        id: 'story-$ownerUid',
        ownerUid: ownerUid,
        ownerName: ownerName,
        createdAt: createdAt,
      ),
    ],
    hasUnseen: hasUnseen,
    isFavorite: isFavorite,
    isCurrentUser: isCurrentUser,
  );
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeFavoriteRepository fakeFavoriteRepository;
  late FakeFeedRepository fakeFeedRepository;
  late FakeNotificationRepository fakeNotificationRepository;
  late _FakeInvitesRepository fakeInvitesRepository;
  late AppUser currentUser;

  setUp(() {
    _trackedStoryTrayRefreshCalls = 0;
    fakeAuthRepository = FakeAuthRepository();
    fakeFavoriteRepository = FakeFavoriteRepository();
    fakeFeedRepository = FakeFeedRepository();
    fakeNotificationRepository = FakeNotificationRepository();
    fakeInvitesRepository = _FakeInvitesRepository();
    _pendingStories = const [];

    currentUser = const AppUser(
      uid: 'current-user',
      email: 'current@example.com',
      nome: 'Current User',
      cadastroStatus: 'perfil_pendente',
      tipoPerfil: AppUserType.professional,
    );
    fakeAuthRepository.appUser = currentUser;
    fakeAuthRepository.emitUser(
      FakeFirebaseUser(uid: 'current-user', email: 'current@example.com'),
    );

    fakeFeedRepository.mainFeedResponse = const PaginatedFeedResponse(
      items: [],
      hasMore: false,
      lastDocument: null,
    );
  });

  Widget createSubject({bool storyTrayFails = false}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(fakeAuthRepository.currentUser),
        ),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(currentUser),
        ),
        favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepository),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepository),
        feedImagePrecacheServiceProvider.overrideWithValue(
          FakeFeedImagePrecacheService(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          fakeNotificationRepository,
        ),
        invitesRepositoryProvider.overrideWithValue(fakeInvitesRepository),
        blockedUsersProvider.overrideWith((ref) => Stream.value(const [])),
        homeGigsPreviewProvider.overrideWith((ref) => Stream.value(const [])),
        currentUserPendingStoriesProvider.overrideWith(
          (ref) async => _pendingStories,
        ),
        storyTrayControllerProvider.overrideWith(
          storyTrayFails
              ? _FailingStoryTrayController.new
              : _StubStoryTrayController.new,
        ),
      ],
      child: const MaterialApp(home: FeedScreen()),
    );
  }

  Widget createRouterSubject({bool trackRefreshes = false}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
        GoRoute(
          path: RoutePaths.storyCreate,
          builder: (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Create story route'),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close create story route'),
                  ),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: '${RoutePaths.storyViewer}/:storyId',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Story viewer route'),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close story viewer route'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(fakeAuthRepository.currentUser),
        ),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(currentUser),
        ),
        favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepository),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepository),
        feedImagePrecacheServiceProvider.overrideWithValue(
          FakeFeedImagePrecacheService(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          fakeNotificationRepository,
        ),
        invitesRepositoryProvider.overrideWithValue(fakeInvitesRepository),
        blockedUsersProvider.overrideWith((ref) => Stream.value(const [])),
        homeGigsPreviewProvider.overrideWith((ref) => Stream.value(const [])),
        currentUserPendingStoriesProvider.overrideWith(
          (ref) async => _pendingStories,
        ),
        storyTrayControllerProvider.overrideWith(
          trackRefreshes
              ? _TrackingStoryTrayController.new
              : _StubStoryTrayController.new,
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('FeedScreen stories tray', () {
    testWidgets('renders the stories tray directly below the feed header', (
      tester,
    ) async {
      _storyTrayBundles = [
        _bundle(
          ownerUid: 'current-user',
          ownerName: 'Current User',
          createdAt: DateTime(2026, 3, 10, 8),
          isCurrentUser: true,
          hasUnseen: false,
        ),
        _bundle(
          ownerUid: 'favorite-user',
          ownerName: 'Favorite User',
          createdAt: DateTime(2026, 3, 10, 9),
          isFavorite: true,
        ),
      ];

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(FeedHeader), findsOneWidget);
      expect(find.byType(StoryTray), findsOneWidget);
      expect(find.text('Seu story'), findsOneWidget);
      expect(find.text('Favorite User'), findsOneWidget);
      expect(find.text('Ver ou publicar'), findsOneWidget);

      final headerTop = tester
          .getTopLeft(find.byKey(const Key('feed_header_profile_card')))
          .dy;
      final trayTop = tester.getTopLeft(find.byType(StoryTray)).dy;

      expect(trayTop, greaterThan(headerTop));
    });

    testWidgets('shows an inline retry state when stories fail to load', (
      tester,
    ) async {
      _storyTrayBundles = const [];

      await tester.pumpWidget(createSubject(storyTrayFails: true));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(StoryTray), findsOneWidget);
      expect(find.text('Nao foi possivel carregar os stories'), findsOneWidget);
      expect(find.text('Erro ao carregar stories'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets(
      'shows a processing hint when the current user video is pending',
      (tester) async {
        _storyTrayBundles = const [];
        _pendingStories = [
          _storyItem(
            id: 'story-processing',
            ownerUid: 'current-user',
            ownerName: 'Current User',
            createdAt: DateTime(2026, 3, 10, 8),
          ).copyWith(status: StoryStatus.processing),
        ];

        await tester.pumpWidget(createSubject());
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Processando'), findsOneWidget);
        expect(find.text('Seu video esta sendo processado'), findsOneWidget);
        expect(find.text('Atualizar'), findsOneWidget);
      },
    );

    testWidgets(
      'opens the viewer after selecting Ver story from current user options',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        _storyTrayBundles = [
          _bundle(
            ownerUid: 'current-user',
            ownerName: 'Current User',
            createdAt: DateTime(2026, 3, 10, 8),
            isCurrentUser: true,
            hasUnseen: false,
          ),
        ];

        await tester.pumpWidget(createRouterSubject());
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.ensureVisible(find.text('Seu story', skipOffstage: false));
        await tester.tap(find.text('Seu story', skipOffstage: false));
        await tester.pumpAndSettle();

        expect(find.text('Ver story'), findsOneWidget);

        await tester.tap(find.text('Ver story'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Story viewer route'), findsOneWidget);
      },
    );

    testWidgets('refreshes the tray after returning from the viewer route', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      _storyTrayBundles = [
        _bundle(
          ownerUid: 'current-user',
          ownerName: 'Current User',
          createdAt: DateTime(2026, 3, 10, 8),
          isCurrentUser: true,
          hasUnseen: false,
        ),
      ];

      await tester.pumpWidget(createRouterSubject(trackRefreshes: true));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.ensureVisible(find.text('Seu story', skipOffstage: false));
      await tester.tap(find.text('Seu story', skipOffstage: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver story'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Story viewer route'), findsOneWidget);

      await tester.tap(find.text('Close story viewer route'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(_trackedStoryTrayRefreshCalls, 1);
    });

    testWidgets(
      'opens the creator after selecting Publicar novo from current user options',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        _storyTrayBundles = [
          _bundle(
            ownerUid: 'current-user',
            ownerName: 'Current User',
            createdAt: DateTime(2026, 3, 10, 8),
            isCurrentUser: true,
            hasUnseen: false,
          ),
        ];

        await tester.pumpWidget(createRouterSubject());
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.ensureVisible(find.text('Seu story', skipOffstage: false));
        await tester.tap(find.text('Seu story', skipOffstage: false));
        await tester.pumpAndSettle();

        expect(find.text('Publicar novo'), findsOneWidget);

        await tester.tap(find.text('Publicar novo'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Create story route'), findsOneWidget);
      },
    );

    testWidgets('refreshes the tray after returning from the creator route', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      _storyTrayBundles = [
        _bundle(
          ownerUid: 'current-user',
          ownerName: 'Current User',
          createdAt: DateTime(2026, 3, 10, 8),
          isCurrentUser: true,
          hasUnseen: false,
        ),
      ];

      await tester.pumpWidget(createRouterSubject(trackRefreshes: true));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.ensureVisible(find.text('Seu story', skipOffstage: false));
      await tester.tap(find.text('Seu story', skipOffstage: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Publicar novo'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Create story route'), findsOneWidget);

      await tester.tap(find.text('Close create story route'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(_trackedStoryTrayRefreshCalls, 1);
    });
  });
}
