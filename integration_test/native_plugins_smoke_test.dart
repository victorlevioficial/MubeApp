import 'dart:async';

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

/// Device-level smoke tests for plugins whose major versions were upgraded.
///
/// Unit tests mock these platform channels, so only a real device/emulator run
/// proves the native side still answers after an upgrade. A broken plugin
/// surfaces here as [MissingPluginException] or [PlatformException].
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('package_info_plus (8 -> 10)', () {
    testWidgets('reports real app metadata from the platform', (tester) async {
      final info = await PackageInfo.fromPlatform();

      expect(info.packageName, isNotEmpty);
      expect(info.version, isNotEmpty);
      expect(info.buildNumber, isNotEmpty);
      // Guards the parsing used by the update notice and store review flows.
      expect(RegExp(r'^\d+\.\d+\.\d+').hasMatch(info.version), isTrue);
    });
  });

  group('image_cropper (11 -> 12)', () {
    testWidgets('native channel answers recoverImage', (tester) async {
      // recoverImage exercises the platform channel without opening the crop
      // activity, so it can run unattended. Null means "nothing to recover".
      await expectLater(ImageCropper().recoverImage(), completes);
    });

    testWidgets('ui settings used by the app still build', (tester) async {
      final settings = AndroidUiSettings(
        toolbarTitle: 'Ajustar Foto',
        toolbarColor: const Color(0xFF0A0A0A),
        toolbarWidgetColor: const Color(0xFFFFFFFF),
        backgroundColor: const Color(0xFF0A0A0A),
        activeControlsWidgetColor: const Color(0xFF7C4DFF),
        lockAspectRatio: true,
        initAspectRatio: CropAspectRatioPreset.square,
        aspectRatioPresets: const [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ],
      );

      expect(settings, isA<AndroidUiSettings>());
    });
  });

  group('facebook_app_events (0.20 -> 0.30)', () {
    testWidgets('advertiser id collection replaces setAdvertiserTracking', (
      tester,
    ) async {
      final client = FacebookAppEvents();

      // The API this migration moved to. A signature/channel break here is
      // exactly what would silently stop Meta Ads attribution.
      await expectLater(
        client.setAdvertiserIdCollectionEnabled(true),
        completes,
      );
      await expectLater(client.setAutoLogAppEventsEnabled(true), completes);
    });

    testWidgets('logs the campaign events the app sends', (tester) async {
      final client = FacebookAppEvents();

      await expectLater(
        client.logEvent(
          name: 'mube_integration_smoke',
          parameters: const {'source': 'integration_test'},
        ),
        completes,
      );
      await expectLater(
        client.logEvent(
          name: 'fb_mobile_complete_registration',
          parameters: const {'fb_registration_method': 'integration_test'},
        ),
        completes,
      );
      await expectLater(client.clearUserID(), completes);
    });
  });

  group('google_fonts (6 -> 8) with bundled font assets', () {
    const bundledFonts = <String>[
      'google_fonts/Poppins-Regular.ttf',
      'google_fonts/Poppins-Medium.ttf',
      'google_fonts/Poppins-SemiBold.ttf',
      'google_fonts/Poppins-Bold.ttf',
      'google_fonts/Poppins-BlackItalic.ttf',
      'google_fonts/Inter-Regular.ttf',
      'google_fonts/Inter-Medium.ttf',
      'google_fonts/Inter-Bold.ttf',
    ];

    testWidgets('every declared font ships inside the app bundle', (
      tester,
    ) async {
      for (final asset in bundledFonts) {
        final data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(1000), reason: asset);
      }
    });

    testWidgets('renders Poppins and Inter with runtime fetching disabled', (
      tester,
    ) async {
      // Mirrors main.dart: with fetching off, a missing asset makes
      // google_fonts throw instead of silently downloading the font.
      final previousSetting = GoogleFonts.config.allowRuntimeFetching;
      GoogleFonts.config.allowRuntimeFetching = false;

      final errors = <Object>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details.exception);

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Mube', style: GoogleFonts.poppins(fontSize: 28)),
                  Text(
                    'Conectando musicos',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  Text('Corpo de texto', style: GoogleFonts.inter()),
                  Text(
                    'Corpo em negrito',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mube'), findsOneWidget);
        expect(errors, isEmpty);
      } finally {
        FlutterError.onError = previousOnError;
        GoogleFonts.config.allowRuntimeFetching = previousSetting;
      }
    });
  });

  group('share_plus (12 -> 13)', () {
    testWidgets('opens the native share sheet for a profile link', (
      tester,
    ) async {
      // share() only completes once the user dismisses the sheet, so a pending
      // future is the success signal: the native sheet is up. A broken plugin
      // would reject immediately instead.
      final shareFuture = SharePlus.instance.share(
        ShareParams(
          text: 'Confira meu perfil no Mube: https://mube.app/u/integration',
          subject: 'Perfil no Mube',
        ),
      );

      Object? failure;
      unawaited(
        shareFuture.then(
          (_) {},
          onError: (Object error) {
            failure = error;
          },
        ),
      );

      await tester.pump(const Duration(seconds: 3));

      expect(
        failure,
        isNull,
        reason: 'native share channel rejected the request: $failure',
      );
    });
  });
}
