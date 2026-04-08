import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/utils/app_logger.dart';

void main() {
  group('AppLogger MatchPoint Crashlytics suppression', () {
    test('suppresses MatchPoint custom keys in release mode', () {
      expect(
        AppLogger.shouldSuppressCrashlyticsCustomKey(
          'mp_step',
          isReleaseMode: true,
        ),
        isTrue,
      );
      expect(
        AppLogger.shouldSuppressCrashlyticsCustomKey(
          'mp_fetch_mode',
          isReleaseMode: true,
        ),
        isTrue,
      );
      expect(
        AppLogger.shouldSuppressCrashlyticsCustomKey(
          'feed_page',
          isReleaseMode: true,
        ),
        isFalse,
      );
    });

    test('suppresses MatchPoint breadcrumbs in release mode', () {
      expect(
        AppLogger.shouldSuppressCrashlyticsBreadcrumb(
          'mp:explore:init',
          isReleaseMode: true,
        ),
        isTrue,
      );
      expect(
        AppLogger.shouldSuppressCrashlyticsBreadcrumb(
          'feed:init',
          isReleaseMode: true,
        ),
        isFalse,
      );
    });

    test('does not suppress MatchPoint diagnostics outside release mode', () {
      expect(
        AppLogger.shouldSuppressCrashlyticsCustomKey(
          'mp_step',
          isReleaseMode: false,
        ),
        isFalse,
      );
      expect(
        AppLogger.shouldSuppressCrashlyticsBreadcrumb(
          'mp:explore:init',
          isReleaseMode: false,
        ),
        isFalse,
      );
    });
  });

  group('AppLogger.shouldTreatFlutterErrorAsFatal', () {
    test('returns false for RenderFlex overflow errors', () {
      final details = FlutterErrorDetails(
        exception: FlutterError(
          'A RenderFlex overflowed by 19 pixels on the bottom.',
        ),
      );

      expect(AppLogger.shouldTreatFlutterErrorAsFatal(details), isFalse);
    });

    test('returns false for infinite layout size errors', () {
      final details = FlutterErrorDetails(
        exception: FlutterError(
          'RenderBox was given an infinite size during layout.',
        ),
      );

      expect(AppLogger.shouldTreatFlutterErrorAsFatal(details), isFalse);
    });

    test('ignores handled image precache 404 errors', () {
      final details = FlutterErrorDetails(
        exception: const HttpException(
          'Invalid statusCode: 404, uri = https://firebasestorage.googleapis.com/example.webp',
        ),
        library: 'image resource service',
        context: ErrorDescription('image failed to precache'),
      );

      expect(AppLogger.isHandledImageFlutterError(details), isTrue);
      expect(AppLogger.shouldTreatFlutterErrorAsFatal(details), isFalse);
      expect(AppLogger.shouldReportFlutterError(details), isFalse);
    });

    test('keeps unexpected framework errors as fatal', () {
      final details = FlutterErrorDetails(
        exception: StateError('unexpected framework failure'),
      );

      expect(AppLogger.shouldTreatFlutterErrorAsFatal(details), isTrue);
      expect(AppLogger.shouldReportFlutterError(details), isTrue);
    });
  });
}
