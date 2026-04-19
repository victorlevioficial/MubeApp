import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_application.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/gigs/presentation/screens/gigs_hub_screen.dart';

import '../../helpers/firebase_test_config.dart';
import '../../helpers/test_data.dart';
import '../../helpers/test_fakes.dart';

/// Integration tests for the gigs feature.
///
/// Wraps `GigsHubScreen` in the full app surface (GoRouter +
/// MaterialApp.router) so navigation assertions exercise the real router
/// stack, complementing the widget-level tests which only verify rendering.
///
/// Coverage:
/// - Empty state when the user has no gigs, applications, or published gigs.
/// - Gig list renders with title and location label for an open gig.
/// - Tapping a gig card routes to the gig detail screen for that id.
Gig _buildOpenGig({
  String id = 'gig-1',
  String title = 'Show no Bar do Cadore',
  String locationLabel = 'Sao Paulo, SP',
  String creatorId = 'creator-1',
}) {
  return Gig(
    id: id,
    title: title,
    description: 'Procuramos banda para abrir o show.',
    gigType: GigType.liveShow,
    status: GigStatus.open,
    dateMode: GigDateMode.toBeArranged,
    locationType: GigLocationType.onsite,
    location: {'label': locationLabel},
    slotsTotal: 2,
    compensationType: CompensationType.negotiable,
    creatorId: creatorId,
  );
}

void main() {
  setUpAll(() async => await setupFirebaseCoreMocks());

  group('Gigs Flow Integration Tests', () {
    late FakeAuthRepository fakeAuthRepo;

    setUp(() {
      fakeAuthRepo = FakeAuthRepository();
      scaffoldMessengerKey.currentState?.clearSnackBars();
    });

    tearDown(() {
      fakeAuthRepo.dispose();
    });

    Future<void> pumpGigsHubApp(
      WidgetTester tester, {
      List<Gig> openGigs = const [],
      List<GigApplication> applications = const [],
      List<Gig> myGigs = const [],
    }) async {
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepo.appUser = user;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const GigsHubScreen(),
          ),
          GoRoute(
            path: '/gigs/:id',
            builder: (context, state) =>
                Scaffold(body: Text('Gig: ${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(user),
            ),
            gigsStreamProvider.overrideWith((ref) => Stream.value(openGigs)),
            myApplicationsProvider.overrideWith(
              (ref) => Stream.value(applications),
            ),
            myGigsStreamProvider.overrideWith((ref) => Stream.value(myGigs)),
            // Avoid hitting the real GigRepository when rendering non-empty
            // lists — the card only needs the creator map, which we stub as
            // empty (the card gracefully handles a missing creator).
            gigUsersByStableIdsProvider.overrideWith(
              (ref, _) => const <String, AppUser>{},
            ),
          ],
          child: MaterialApp.router(
            scaffoldMessengerKey: scaffoldMessengerKey,
            routerConfig: router,
            theme: ThemeData.dark(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows empty state when there are no open gigs', (
      tester,
    ) async {
      await pumpGigsHubApp(tester);

      expect(find.byType(GigsHubScreen), findsOneWidget);
      // "Abertas" tab is selected by default — GigsScreen renders this copy
      // when the gigs stream resolves to an empty list.
      expect(find.text('Nenhuma gig encontrada'), findsOneWidget);
    });

    testWidgets('lists an open gig with title and location', (tester) async {
      final gig = _buildOpenGig(
        id: 'gig-1',
        title: 'Show no Bar do Cadore',
        locationLabel: 'Sao Paulo, SP',
      );

      await pumpGigsHubApp(tester, openGigs: [gig]);

      expect(find.text('Show no Bar do Cadore'), findsOneWidget);
      expect(find.text('Sao Paulo, SP'), findsOneWidget);
    });

    testWidgets('tapping a gig card navigates to gig detail', (tester) async {
      final gig = _buildOpenGig(id: 'gig-42', title: 'Jam session');

      await pumpGigsHubApp(tester, openGigs: [gig]);

      expect(find.text('Jam session'), findsOneWidget);

      await tester.tap(find.text('Jam session'));
      await tester.pumpAndSettle();

      expect(find.text('Gig: gig-42'), findsOneWidget);
    });
  });
}
