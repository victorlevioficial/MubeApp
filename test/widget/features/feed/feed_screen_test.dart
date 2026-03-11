import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/feedback/empty_state_widget.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/paginated_feed_response.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:mube/src/features/feed/presentation/feed_screen.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_skeleton.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/notifications/data/notification_repository.dart';
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
        await tester.pumpAndSettle(const Duration(seconds: 2));
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

    testWidgets(
      'keeps full screen skeleton until gigs preview resolves on first render',
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

        expect(find.byType(FeedScreenSkeleton), findsOneWidget);

        gigsPreviewController.add(const []);
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(CustomScrollView), findsOneWidget);
      },
    );
  });
}
