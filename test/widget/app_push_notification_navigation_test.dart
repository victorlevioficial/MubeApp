import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/app.dart';
import 'package:mube/src/core/providers/app_update_provider.dart';
import 'package:mube/src/core/providers/connectivity_provider.dart';
import 'package:mube/src/core/services/push_notification_event_bus.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/routing/app_router.dart';
import 'package:mube/src/routing/route_paths.dart';

import '../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Push notification navigation', () {
    testWidgets('replays a gig notification after boot routes unlock', (
      tester,
    ) async {
      final harness = _PushNavigationHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Splash Placeholder'), findsOneWidget);

      PushNotificationEventBus.instance.emitNavigation(
        const PushNavigationIntent(route: '/gigs/gig-123'),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Splash Placeholder'), findsOneWidget);

      harness.releaseBootGate();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Gig Placeholder: gig-123'), findsOneWidget);
    });
  });
}

class _PushNavigationHarness {
  _PushNavigationHarness()
    : _fakeAuthRepository = FakeAuthRepository(),
      _bootGate = ValueNotifier<bool>(false) {
    router = _buildRouter(bootGate: _bootGate);
  }

  final FakeAuthRepository _fakeAuthRepository;
  final ValueNotifier<bool> _bootGate;
  late final GoRouter router;

  Widget build() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_fakeAuthRepository),
        goRouterProvider.overrideWithValue(router),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<firebase_auth.User?>.value(null),
        ),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream<AppUser?>.value(null),
        ),
        appUpdateNoticeProvider.overrideWith((ref) async => null),
        pendingGigReviewsProvider.overrideWith((ref) async => const []),
        connectivityProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatus.online),
        ),
      ],
      child: const MubeApp(),
    );
  }

  void releaseBootGate() {
    _bootGate.value = true;
  }

  Future<void> dispose() async {
    router.dispose();
    _bootGate.dispose();
    _fakeAuthRepository.dispose();
  }

  static GoRouter _buildRouter({required ValueNotifier<bool> bootGate}) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: RoutePaths.splash,
      refreshListenable: bootGate,
      redirect: (context, state) {
        final currentPath = state.uri.path;
        if (!bootGate.value && currentPath != RoutePaths.splash) {
          return RoutePaths.splash;
        }
        if (bootGate.value && currentPath == RoutePaths.splash) {
          return RoutePaths.feed;
        }
        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: RoutePaths.splash,
          builder: (context, state) =>
              const _PlaceholderScreen('Splash Placeholder'),
        ),
        GoRoute(
          path: RoutePaths.feed,
          builder: (context, state) =>
              const _PlaceholderScreen('Feed Placeholder'),
        ),
        GoRoute(
          path: '${RoutePaths.gigs}/:gigId',
          builder: (context, state) => _PlaceholderScreen(
            'Gig Placeholder: ${state.pathParameters['gigId']}',
          ),
        ),
      ],
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
