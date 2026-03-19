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
import 'package:mube/src/core/services/store_review_service.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/routing/app_router.dart';
import 'package:mube/src/routing/route_paths.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_data.dart';
import '../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('does not request store review on blocked routes and resumes on feed', (
    tester,
  ) async {
    final harness = _StoreReviewHarness(initialLocation: RoutePaths.login);
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();

    expect(harness.platformClient.requestReviewCalls, 0);

    harness.router.go(RoutePaths.feed);
    await tester.pumpAndSettle();

    expect(harness.platformClient.requestReviewCalls, 1);
  });

  testWidgets('waits until the app update notice is dismissed before requesting review', (
    tester,
  ) async {
    final harness = _StoreReviewHarness(
      initialLocation: RoutePaths.feed,
      notice: const AppUpdateNotice(
        platform: TargetPlatform.android,
        installedBuildNumber: 43,
        minimumBuildNumber: 44,
        installedVersion: '1.5.2',
        storeUrl: 'https://play.google.com/store/apps/details?id=com.mube.mubeoficial',
      ),
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();

    expect(find.text('Atualizacao disponivel'), findsOneWidget);
    expect(harness.platformClient.requestReviewCalls, 0);

    await tester.tap(find.text('Depois'));
    await tester.pumpAndSettle();

    expect(harness.platformClient.requestReviewCalls, 1);
  });
}

class _StoreReviewHarness {
  _StoreReviewHarness({required String initialLocation, this.notice})
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
        ],
      ),
      platformClient = _FakeStoreReviewPlatformClient() {
    _profile = TestData.user(uid: 'user-1', email: 'user-1@mube.app');
    final authUser = FakeFirebaseUser(uid: _profile.uid, email: _profile.email);
    _fakeAuthRepository.emitUser(authUser);
    _authController.add(authUser);
    _profileController.add(_profile);
  }

  final FakeAuthRepository _fakeAuthRepository;
  final StreamController<firebase_auth.User?> _authController;
  final StreamController<AppUser?> _profileController;
  final AppUpdateNotice? notice;
  final GoRouter router;
  final _FakeStoreReviewPlatformClient platformClient;
  late final AppUser _profile;

  Widget build() {
    return FutureBuilder<void>(
      future: _seedStoreReviewState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        return ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_fakeAuthRepository),
            goRouterProvider.overrideWithValue(router),
            authStateChangesProvider.overrideWith((ref) => _authController.stream),
            currentUserProfileProvider.overrideWith((ref) => _profileController.stream),
            appUpdateNoticeProvider.overrideWith((ref) async => notice),
            storeReviewServiceProvider.overrideWithValue(
              StoreReviewService(
                currentUserUidLoader: () =>
                    _fakeAuthRepository.currentUser?.uid,
                analytics: FakeAnalyticsService(),
                sharedPreferencesLoader: SharedPreferences.getInstance,
                packageInfoLoader: () async => PackageInfo(
                  appName: 'Mube',
                  packageName: 'com.mube.mubeoficial',
                  version: '1.5.2',
                  buildNumber: '43',
                  buildSignature: '',
                ),
                platformClient: platformClient,
                urlLauncher: (uri) async => true,
                clock: () => DateTime(2026, 3, 19, 12),
                platformResolver: () => TargetPlatform.android,
              ),
            ),
            pendingGigReviewsProvider.overrideWith((ref) async => const []),
            feedControllerProvider.overrideWith(_StubFeedController.new),
            connectivityProvider.overrideWith(
              (ref) => Stream.value(ConnectivityStatus.online),
            ),
          ],
          child: const MubeApp(),
        );
      },
    );
  }

  Future<void> dispose() async {
    router.dispose();
    await _authController.close();
    await _profileController.close();
    _fakeAuthRepository.dispose();
  }

  Future<void> _seedStoreReviewState() async {
    SharedPreferences.setMockInitialValues({
      'store_review.${_profile.uid}.session_count': 3,
      'store_review.${_profile.uid}.pending_automatic_trigger':
          StoreReviewTrigger.gigReviewSubmitted.name,
    });
  }
}

class _FakeStoreReviewPlatformClient implements StoreReviewPlatformClient {
  int requestReviewCalls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async {
    requestReviewCalls += 1;
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
