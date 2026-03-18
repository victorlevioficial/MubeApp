import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/app.dart';
import 'package:mube/src/core/providers/app_update_provider.dart';
import 'package:mube/src/core/providers/connectivity_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';
import 'package:mube/src/features/gigs/domain/gig_review_opportunity.dart';
import 'package:mube/src/features/gigs/domain/review_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/routing/app_router.dart';
import 'package:mube/src/routing/route_paths.dart';

import '../helpers/test_data.dart';
import '../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gig review reminder', () {
    testWidgets('shows pending review and navigates only once per session', (
      tester,
    ) async {
      final harness = _GigReviewReminderHarness(
        pendingReviews: const [
          GigReviewOpportunity(
            gigId: 'gig-42',
            gigTitle: 'Festival Teste',
            reviewedUserId: 'user-7',
            reviewedUserName: 'Maria',
            reviewedUserPhoto: 'https://example.com/photo.jpg',
            reviewType: ReviewType.creatorToParticipant,
          ),
        ],
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      harness.emitAuthenticatedUser(_completedProfile());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Avaliacao pendente'), findsOneWidget);
      expect(find.textContaining('Maria'), findsOneWidget);

      await tester.tap(find.text('Avaliar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Review Placeholder: gig-42:user-7:Maria:Festival Teste'),
        findsOneWidget,
      );

      harness.router.pop();
      await tester.pumpAndSettle();

      expect(find.text('Feed Placeholder'), findsOneWidget);
      expect(find.text('Avaliacao pendente'), findsNothing);
    });
  });
}

class _GigReviewReminderHarness {
  _GigReviewReminderHarness({required this.pendingReviews})
    : _fakeAuthRepository = FakeAuthRepository(),
      _authController = StreamController<firebase_auth.User?>.broadcast(),
      _profileController = StreamController<AppUser?>.broadcast(),
      router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: RoutePaths.feed,
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.login,
            builder: (context, state) =>
                const _PlaceholderScreen('Login Placeholder'),
          ),
          GoRoute(
            path: RoutePaths.feed,
            builder: (context, state) =>
                const _PlaceholderScreen('Feed Placeholder'),
          ),
          GoRoute(
            path: '${RoutePaths.gigs}/:gigId/review/:userId',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return _PlaceholderScreen(
                'Review Placeholder: '
                '${state.pathParameters['gigId']}:'
                '${state.pathParameters['userId']}:'
                '${extra?['userName']}:'
                '${extra?['gigTitle']}',
              );
            },
          ),
        ],
      );

  final FakeAuthRepository _fakeAuthRepository;
  final StreamController<firebase_auth.User?> _authController;
  final StreamController<AppUser?> _profileController;
  final List<GigReviewOpportunity> pendingReviews;
  final GoRouter router;

  Widget build() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_fakeAuthRepository),
        goRouterProvider.overrideWithValue(router),
        authStateChangesProvider.overrideWith((ref) => _authController.stream),
        currentUserProfileProvider.overrideWith(
          (ref) => _profileController.stream,
        ),
        appUpdateNoticeProvider.overrideWith((ref) async => null),
        pendingGigReviewsProvider.overrideWith((ref) async => pendingReviews),
        feedControllerProvider.overrideWith(_StubFeedController.new),
        connectivityProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatus.online),
        ),
      ],
      child: const MubeApp(),
    );
  }

  void emitAuthenticatedUser(AppUser profile) {
    final authUser = FakeFirebaseUser(uid: profile.uid, email: profile.email);
    _fakeAuthRepository.emitUser(authUser);
    _authController.add(authUser);
    _profileController.add(profile);
  }

  Future<void> dispose() async {
    router.dispose();
    await _authController.close();
    await _profileController.close();
    _fakeAuthRepository.dispose();
  }
}

class _StubFeedController extends FeedController {
  @override
  FutureOr<FeedState> build() => const FeedState();

  @override
  Future<void> loadAllData() async {}
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

AppUser _completedProfile() {
  return TestData.user(uid: 'reviewer-1', email: 'reviewer@mube.app');
}
