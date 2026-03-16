import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
// ignore: depend_on_referenced_packages
import 'package:firebase_app_check_platform_interface/firebase_app_check_platform_interface.dart'
    show WebProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/splash/providers/app_bootstrap_provider.dart';

class _RecordingFirebaseAppCheck extends Fake
    implements app_check.FirebaseAppCheck {
  app_check.AndroidAppCheckProvider? providerAndroid;
  app_check.AppleAppCheckProvider? providerApple;

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
    this.providerAndroid = providerAndroid;
    this.providerApple = providerApple;
  }
}

void main() {
  group('initializeAppCheck', () {
    test(
      'uses the configured debug token on Android and iOS in debug mode',
      () async {
        final appCheck = _RecordingFirebaseAppCheck();

        await initializeAppCheck(appCheck);

        expect(
          appCheck.providerAndroid,
          isA<app_check.AndroidDebugProvider>().having(
            (provider) => provider.debugToken,
            'debugToken',
            '11111111-2222-4333-8444-555555555555',
          ),
        );
        expect(
          appCheck.providerApple,
          isA<app_check.AppleDebugProvider>().having(
            (provider) => provider.debugToken,
            'debugToken',
            '11111111-2222-4333-8444-555555555555',
          ),
        );
      },
    );
  });
}
