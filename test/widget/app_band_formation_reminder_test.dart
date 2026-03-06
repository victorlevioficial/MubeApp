import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/app.dart';
import 'package:mube/src/core/providers/connectivity_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/bands/presentation/band_formation_reminder_dialog.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';
import 'package:mube/src/routing/app_router.dart';
import 'package:mube/src/routing/route_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_data.dart';
import '../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Band formation reminder', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
    });

    testWidgets(
      'shows once on session start and does not reappear during navigation',
      (tester) async {
        final harness = _ReminderAppHarness(initialLocation: RoutePaths.feed);

        addTearDown(harness.dispose);

        await tester.pumpWidget(harness.build());
        await tester.pumpAndSettle();

        harness.emitAuthenticatedBand(_bandProfile(confirmedMembers: 1));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(BandFormationReminderDialog), findsOneWidget);
        expect(find.text('Sua banda ainda está em formação'), findsOneWidget);

        await tester.tap(find.text('Agora não'));
        await tester.pumpAndSettle();

        expect(find.text('Feed Placeholder'), findsOneWidget);
        expect(find.byType(BandFormationReminderDialog), findsNothing);

        harness.router.go(RoutePaths.manageMembers);
        await tester.pumpAndSettle();

        expect(find.text('Manage Members Placeholder'), findsOneWidget);
        expect(find.byType(BandFormationReminderDialog), findsNothing);

        harness.router.go(RoutePaths.feed);
        await tester.pumpAndSettle();

        expect(find.text('Feed Placeholder'), findsOneWidget);
        expect(find.byType(BandFormationReminderDialog), findsNothing);
      },
    );

    testWidgets(
      'shows when a new authenticated band session starts and CTA navigates',
      (tester) async {
        final harness = _ReminderAppHarness(initialLocation: RoutePaths.feed);

        addTearDown(harness.dispose);

        await tester.pumpWidget(harness.build());
        await tester.pumpAndSettle();

        expect(find.text('Feed Placeholder'), findsOneWidget);
        expect(find.byType(BandFormationReminderDialog), findsNothing);

        final profile = _bandProfile(confirmedMembers: 1);
        harness.emitAuthUser(profile);
        await tester.pumpAndSettle();

        expect(find.text('Feed Placeholder'), findsOneWidget);
        expect(find.byType(BandFormationReminderDialog), findsNothing);

        harness.emitProfile(profile);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(BandFormationReminderDialog), findsOneWidget);

        await tester.tap(find.text('Gerenciar integrantes'));
        await tester.pumpAndSettle();

        expect(find.text('Manage Members Placeholder'), findsOneWidget);
        expect(find.byType(BandFormationReminderDialog), findsNothing);
      },
    );

    testWidgets('does not show when band already has minimum members', (
      tester,
    ) async {
      final harness = _ReminderAppHarness(initialLocation: RoutePaths.feed);

      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      harness.emitAuthenticatedBand(_bandProfile(confirmedMembers: 2));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Feed Placeholder'), findsOneWidget);
      expect(find.byType(BandFormationReminderDialog), findsNothing);
    });
  });
}

class _ReminderAppHarness {
  _ReminderAppHarness({required String initialLocation})
    : _fakeAuthRepository = FakeAuthRepository(),
      _authController = StreamController<firebase_auth.User?>.broadcast(),
      _profileController = StreamController<AppUser?>.broadcast(),
      router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: initialLocation,
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
            path: RoutePaths.manageMembers,
            builder: (context, state) =>
                const _PlaceholderScreen('Manage Members Placeholder'),
          ),
        ],
      );

  final FakeAuthRepository _fakeAuthRepository;
  final StreamController<firebase_auth.User?> _authController;
  final StreamController<AppUser?> _profileController;
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
        feedControllerProvider.overrideWith(_StubFeedController.new),
        connectivityProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatus.online),
        ),
      ],
      child: const MubeApp(),
    );
  }

  void emitAuthenticatedBand(AppUser profile) {
    emitAuthUser(profile);
    emitProfile(profile);
  }

  void emitAuthUser(AppUser profile) {
    final authUser = FakeFirebaseUser(uid: profile.uid, email: profile.email);
    _fakeAuthRepository.emitUser(authUser);
    _authController.add(authUser);
  }

  void emitProfile(AppUser profile) {
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
  final String label;

  const _PlaceholderScreen(this.label);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

AppUser _bandProfile({required int confirmedMembers}) {
  return TestData.user(
    uid: 'band-1',
    email: 'band@mube.app',
    tipoPerfil: AppUserType.band,
    status: 'rascunho',
  ).copyWith(
    dadosBanda: const {'nomeBanda': 'Banda Teste'},
    members: List<String>.generate(
      confirmedMembers,
      (index) => 'member-$index',
    ),
  );
}
