import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/domain/app_config.dart';
import 'package:mube/src/core/domain/app_update_notice.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('resolveAppUpdateNotice', () {
    test('returns android notice with Play Store fallback url', () {
      const config = AppConfig(minAndroidBuildNumber: 25);
      final packageInfo = PackageInfo(
        appName: 'Mube',
        packageName: 'com.mube.app',
        version: '1.3.5',
        buildNumber: '24',
      );

      final notice = resolveAppUpdateNotice(
        config: config,
        packageInfo: packageInfo,
        platform: TargetPlatform.android,
      );

      expect(notice, isNotNull);
      expect(notice!.minimumBuildNumber, 25);
      expect(notice.installedBuildNumber, 24);
      expect(
        notice.storeUri,
        Uri.parse('https://play.google.com/store/apps/details?id=com.mube.app'),
      );
    });

    test('returns ios notice only when App Store url exists in config', () {
      const config = AppConfig(
        minIosBuildNumber: 30,
        iosStoreUrl: 'https://apps.apple.com/br/app/id1234567890',
      );
      final packageInfo = PackageInfo(
        appName: 'Mube',
        packageName: 'com.mube.app',
        version: '1.3.5',
        buildNumber: '24',
      );

      final notice = resolveAppUpdateNotice(
        config: config,
        packageInfo: packageInfo,
        platform: TargetPlatform.iOS,
      );

      expect(notice, isNotNull);
      expect(
        notice!.storeUri,
        Uri.parse('https://apps.apple.com/br/app/id1234567890'),
      );
    });

    test('returns null when installed build is already up to date', () {
      const config = AppConfig(minAndroidBuildNumber: 24);
      final packageInfo = PackageInfo(
        appName: 'Mube',
        packageName: 'com.mube.app',
        version: '1.3.5',
        buildNumber: '24',
      );

      final notice = resolveAppUpdateNotice(
        config: config,
        packageInfo: packageInfo,
        platform: TargetPlatform.android,
      );

      expect(notice, isNull);
    });
  });
}
