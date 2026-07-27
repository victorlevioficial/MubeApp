import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/analytics/meta_analytics_service.dart';

void main() {
  group('shouldEnableMetaAnalytics', () {
    test('disables unsupported platforms', () {
      expect(
        shouldEnableMetaAnalytics(
          isReleaseMode: true,
          isSupportedPlatform: false,
        ),
        isFalse,
      );
    });

    test('disables debug traffic by default', () {
      expect(
        shouldEnableMetaAnalytics(
          isReleaseMode: false,
          isSupportedPlatform: true,
        ),
        isFalse,
      );
    });

    test('enables supported release builds', () {
      expect(
        shouldEnableMetaAnalytics(
          isReleaseMode: true,
          isSupportedPlatform: true,
        ),
        isTrue,
      );
    });

    test('allows explicit debug opt-in', () {
      expect(
        shouldEnableMetaAnalytics(
          isReleaseMode: false,
          isSupportedPlatform: true,
          enableInDebug: true,
        ),
        isTrue,
      );
    });
  });
}
