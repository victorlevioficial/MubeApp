import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/app.dart';
import 'package:mube/src/core/providers/app_display_preferences_provider.dart';
import 'package:mube/src/core/providers/app_update_provider.dart';
import 'package:mube/src/core/providers/connectivity_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';
import 'package:mube/src/routing/app_router.dart';
import 'package:mube/src/routing/route_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MubeApp display configuration', () {
    testWidgets('uses generated locales and persisted display preferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        appLocaleCodePreferenceKey: 'en',
        appThemeModePreferenceKey: 'dark',
      });

      final harness = _DisplayConfigurationHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      await tester.pump();
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('en'));
      expect(app.themeMode, ThemeMode.dark);
      expect(app.supportedLocales, isNotEmpty);
      expect(app.supportedLocales, contains(const Locale('pt')));
      expect(app.supportedLocales, contains(const Locale('en')));
      expect(app.highContrastDarkTheme, isNotNull);
    });
  });
}

class _DisplayConfigurationHarness {
  _DisplayConfigurationHarness()
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
        ],
      );

  final FakeAuthRepository _fakeAuthRepository;
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
        appUpdateNoticeProvider.overrideWith((ref) async => null),
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
