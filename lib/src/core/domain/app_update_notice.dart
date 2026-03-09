import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_config.dart';

class AppUpdateNotice {
  const AppUpdateNotice({
    required this.platform,
    required this.installedBuildNumber,
    required this.minimumBuildNumber,
    required this.installedVersion,
    required this.storeUrl,
  });

  final TargetPlatform platform;
  final int installedBuildNumber;
  final int minimumBuildNumber;
  final String installedVersion;
  final String? storeUrl;

  Uri? get storeUri {
    final normalized = storeUrl?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return Uri.tryParse(normalized);
  }
}

AppUpdateNotice? resolveAppUpdateNotice({
  required AppConfig config,
  required PackageInfo packageInfo,
  required TargetPlatform platform,
  bool isWeb = false,
}) {
  if (isWeb) return null;

  final int minimumBuildNumber;
  final String? storeUrl;

  switch (platform) {
    case TargetPlatform.android:
      minimumBuildNumber = config.minAndroidBuildNumber;
      storeUrl = config.androidStoreUrl?.trim().isNotEmpty == true
          ? config.androidStoreUrl!.trim()
          : _buildAndroidStoreUrl(packageInfo.packageName);
      break;
    case TargetPlatform.iOS:
      minimumBuildNumber = config.minIosBuildNumber;
      storeUrl = config.iosStoreUrl;
      break;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return null;
  }

  if (minimumBuildNumber <= 0) return null;

  final installedBuildNumber = int.tryParse(packageInfo.buildNumber.trim());
  if (installedBuildNumber == null) return null;
  if (installedBuildNumber >= minimumBuildNumber) return null;

  return AppUpdateNotice(
    platform: platform,
    installedBuildNumber: installedBuildNumber,
    minimumBuildNumber: minimumBuildNumber,
    installedVersion: packageInfo.version.trim(),
    storeUrl: storeUrl,
  );
}

String? _buildAndroidStoreUrl(String packageName) {
  final normalizedPackageName = packageName.trim();
  if (normalizedPackageName.isEmpty) return null;
  return 'https://play.google.com/store/apps/details?id=$normalizedPackageName';
}
