import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/l10n/generated/app_localizations.dart';
import 'package:mube/src/core/services/store_review_service.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/settings/presentation/settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('manual rate app action opens Play Store fallback on Android', (
    tester,
  ) async {
    final fakeAuthRepository = FakeAuthRepository();
    final user = TestData.user(
      uid: 'user-1',
      email: 'user-1@mube.app',
      tipoPerfil: AppUserType.professional,
    );
    fakeAuthRepository.emitUser(
      FakeFirebaseUser(uid: user.uid, email: user.email),
    );

    final launchedUris = <Uri>[];
    final service = StoreReviewService(
      currentUserUidLoader: () => fakeAuthRepository.currentUser?.uid,
      analytics: FakeAnalyticsService(),
      sharedPreferencesLoader: SharedPreferences.getInstance,
      packageInfoLoader: () async => PackageInfo(
        appName: 'Mube',
        packageName: 'com.mube.mubeoficial',
        version: '1.5.2',
        buildNumber: '43',
        buildSignature: '',
      ),
      platformClient: _UnavailableStoreReviewPlatformClient(),
      urlLauncher: (uri) async {
        launchedUris.add(uri);
        return true;
      },
      clock: () => DateTime(2026, 3, 19, 12),
      platformResolver: () => TargetPlatform.android,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
          storeReviewServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Avaliar o app'));
    await tester.tap(find.text('Avaliar o app'));
    await tester.pumpAndSettle();

    expect(launchedUris, <Uri>[
      Uri.parse(
        'https://play.google.com/store/apps/details?id=com.mube.mubeoficial',
      ),
    ]);
  });
}

class _UnavailableStoreReviewPlatformClient
    implements StoreReviewPlatformClient {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> requestReview() async {}
}
