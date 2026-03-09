import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/app_update_notice.dart';
import 'app_config_provider.dart';

typedef PackageInfoLoader = Future<PackageInfo> Function();
typedef AppUpdateLauncher = Future<bool> Function(Uri uri);

final packageInfoLoaderProvider = Provider<PackageInfoLoader>((ref) {
  return PackageInfo.fromPlatform;
});

final appUpdateLauncherProvider = Provider<AppUpdateLauncher>((ref) {
  return (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
});

final appUpdateNoticeProvider = FutureProvider<AppUpdateNotice?>((ref) async {
  if (kIsWeb) return null;

  final platform = defaultTargetPlatform;
  if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
    return null;
  }

  final config = await ref.watch(appConfigProvider.future);
  final packageInfo = await ref.watch(packageInfoLoaderProvider)();

  return resolveAppUpdateNotice(
    config: config,
    packageInfo: packageInfo,
    platform: platform,
    isWeb: kIsWeb,
  );
});
