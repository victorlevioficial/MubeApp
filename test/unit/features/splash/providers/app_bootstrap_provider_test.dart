import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
// ignore: depend_on_referenced_packages
import 'package:firebase_app_check_platform_interface/firebase_app_check_platform_interface.dart'
    show WebProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/splash/providers/app_bootstrap_provider.dart';

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
}
