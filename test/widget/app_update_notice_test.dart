import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/app.dart';
import 'package:mube/src/core/domain/app_update_notice.dart';
import 'package:mube/src/core/providers/app_update_provider.dart';
import 'package:mube/src/core/providers/connectivity_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';
import 'package:mube/src/routing/app_router.dart';
import 'package:mube/src/routing/route_paths.dart';

import '../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App update notice', () {
    testWidgets('blocks app usage until update', (tester) async {
      final launchedUris = <Uri>[];
      final harness = _AppUpdateHarness(
        notice: const AppUpdateNotice(
          platform: TargetPlatform.android,
          installedBuildNumber: 24,
          minimumBuildNumber: 25,
          installedVersion: '1.3.5',
          storeUrl:
              'https://play.google.com/store/apps/details?id=com.mube.app',
        ),
        onLaunch: (uri) async {
          launchedUris.add(uri);
          return true;
        },
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Atualizacao necessaria'), findsOneWidget);
      expect(
        find.textContaining('Voce esta usando a versao 1.3.5'),
        findsOneWidget,
      );
      expect(launchedUris, isEmpty);

      harness.router.go(RoutePaths.login);
      await tester.pumpAndSettle();

      expect(find.text('Login Placeholder'), findsOneWidget);
      expect(find.text('Atualizacao necessaria'), findsOneWidget);
    });

    testWidgets('opens store and keeps update gate visible', (tester) async {
      final launchedUris = <Uri>[];
      final harness = _AppUpdateHarness(
        notice: const AppUpdateNotice(
          platform: TargetPlatform.iOS,
          installedBuildNumber: 24,
          minimumBuildNumber: 30,
          installedVersion: '1.3.5',
          storeUrl: 'https://apps.apple.com/br/app/id1234567890',
        ),
        onLaunch: (uri) async {
          launchedUris.add(uri);
          return true;
        },
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Atualizar agora'));
      await tester.pumpAndSettle();

      expect(launchedUris, <Uri>[
        Uri.parse('https://apps.apple.com/br/app/id1234567890'),
      ]);
      expect(find.text('Atualizacao necessaria'), findsOneWidget);
    });
  });
}

class _AppUpdateHarness {
  _AppUpdateHarness({required this.notice, required this.onLaunch})
    : _fakeAuthRepository = FakeAuthRepository(),
      router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: RoutePaths.feed,
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.feed,
            builder: (context, state) =>
                const _PlaceholderScreen('Feed Placeholder'),
          ),
          GoRoute(
            path: RoutePaths.login,
            builder: (context, state) =>
                const _PlaceholderScreen('Login Placeholder'),
          ),
        ],
      );

  final FakeAuthRepository _fakeAuthRepository;
  final AppUpdateNotice? notice;
  final Future<bool> Function(Uri uri) onLaunch;
  final GoRouter router;

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
        appUpdateNoticeProvider.overrideWith((ref) async => notice),
        appUpdateLauncherProvider.overrideWithValue(onLaunch),
        feedControllerProvider.overrideWith(_StubFeedController.new),
        connectivityProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatus.online),
        ),
      ],
      child: const MubeApp(),
    );
  }

  Future<void> dispose() async {
    router.dispose();
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
