import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
// ignore: depend_on_referenced_packages
import 'package:firebase_app_check_platform_interface/firebase_app_check_platform_interface.dart'
    show WebProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/features/splash/providers/app_bootstrap_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingFirebaseAppCheck extends Fake
    implements app_check.FirebaseAppCheck {
  int activateCalls = 0;
  bool tokenAutoRefreshEnabled = false;
  app_check.AndroidAppCheckProvider? providerAndroid;
  app_check.AppleAppCheckProvider? providerApple;
  final StreamController<String?> _tokenChanges =
      StreamController<String?>.broadcast();

  @override
  Stream<String?> get onTokenChange => _tokenChanges.stream;

  @override
  Future<void> activate({
    WebProvider? webProvider,
    WebProvider? providerWeb,
    app_check.AndroidProvider androidProvider =
        app_check.AndroidProvider.playIntegrity,
    app_check.AppleProvider appleProvider = app_check.AppleProvider.deviceCheck,
    app_check.AndroidAppCheckProvider providerAndroid =
        const app_check.AndroidPlayIntegrityProvider(),
    app_check.AppleAppCheckProvider providerApple =
        const app_check.AppleDeviceCheckProvider(),
  }) async {
    activateCalls += 1;
    this.providerAndroid = providerAndroid;
    this.providerApple = providerApple;
  }

  @override
  Future<String?> getToken([bool? forceRefresh]) async => null;

  @override
  Future<void> setTokenAutoRefreshEnabled(
    bool isTokenAutoRefreshEnabled,
  ) async {
    tokenAutoRefreshEnabled = isTokenAutoRefreshEnabled;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('initializeAppCheck', () {
    setUp(resetAppCheckActivationState);
    tearDown(resetAppCheckActivationState);

    test(
      'uses SDK-generated debug tokens when no explicit token is configured',
      () async {
        final appCheck = _RecordingFirebaseAppCheck();

        await initializeAppCheck(appCheck);

        expect(
          appCheck.providerAndroid,
          isA<app_check.AndroidDebugProvider>().having(
            (provider) => provider.debugToken,
            'debugToken',
            isNull,
          ),
        );
        expect(
          appCheck.providerApple,
          isA<app_check.AppleDebugProvider>().having(
            (provider) => provider.debugToken,
            'debugToken',
            isNull,
          ),
        );
      },
    );

    test(
      'deduplicates app check activation across concurrent callers',
      () async {
        final appCheck = _RecordingFirebaseAppCheck();

        await Future.wait([
          ensureAppCheckActivated(appCheck),
          ensureAppCheckActivated(appCheck),
        ]);

        expect(appCheck.activateCalls, 1);
        expect(appCheck.tokenAutoRefreshEnabled, isTrue);
      },
    );
  });

  group('AppBootstrapNotifier', () {
    setUp(resetAppCheckActivationState);
    tearDown(resetAppCheckActivationState);

    test(
      'marks bootstrap as ready without waiting for app check activation',
      () async {
        SharedPreferences.setMockInitialValues(const <String, Object>{});
        final activationCompleter = Completer<void>();
        final container = ProviderContainer(
          overrides: [
            appCheckBootstrapperProvider.overrideWithValue(
              () => activationCompleter.future,
            ),
            sharedPreferencesLoaderProvider.overrideWithValue(
              SharedPreferences.getInstance,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(appBootstrapProvider.notifier)
            .start()
            .timeout(const Duration(milliseconds: 100));

        expect(container.read(appBootstrapProvider), AppBootstrapState.ready);
        expect(activationCompleter.isCompleted, isFalse);

        activationCompleter.complete();
        await Future<void>.delayed(Duration.zero);
      },
    );
  });
}
