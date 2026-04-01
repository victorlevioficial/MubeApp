import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/services/store_review_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _RecordingAnalyticsService analytics;
  late _FakeStoreReviewPlatformClient platformClient;
  late List<Uri> launchedUris;
  late DateTime now;
  late String? currentUid;

  StoreReviewService createService({
    TargetPlatform platform = TargetPlatform.android,
    String? iosAppStoreId,
    bool urlLaunchResult = true,
    Object? urlLaunchError,
  }) {
    return StoreReviewService(
      currentUserUidLoader: () => currentUid,
      analytics: analytics,
      sharedPreferencesLoader: SharedPreferences.getInstance,
      packageInfoLoader: () async => PackageInfo(
        appName: 'Mube',
        packageName: 'com.mube.mubeoficial',
        version: '1.5.2',
        buildNumber: '43',
        buildSignature: '',
      ),
      platformClient: platformClient,
      urlLauncher: (uri) async {
        launchedUris.add(uri);
        if (urlLaunchError != null) {
          throw urlLaunchError;
        }
        return urlLaunchResult;
      },
      clock: () => now,
      platformResolver: () => platform,
      iosAppStoreId: iosAppStoreId,
    );
  }

  setUp(() {
    analytics = _RecordingAnalyticsService();
    platformClient = _FakeStoreReviewPlatformClient();
    launchedUris = <Uri>[];
    now = DateTime(2026, 3, 19, 12);
    currentUid = 'user-1';
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test(
    'requests automatic review after minimum sessions and pending trigger',
    () async {
      final service = createService();

      await service.registerCurrentSession();
      await service.registerCurrentSession();
      await service.registerCurrentSession();
      await service.recordTrigger(StoreReviewTrigger.gigReviewSubmitted);

      final result = await service.requestIfEligible();
      final state = await service.debugLoadState('user-1');

      expect(result, StoreReviewAutomaticRequestResult.prompted);
      expect(platformClient.requestReviewCalls, 1);
      expect(state.sessionCount, 3);
      expect(state.promptCount, 1);
      expect(state.pendingAutomaticTrigger, isNull);
      expect(state.lastPromptedVersion, '1.5.2+43');
      expect(analytics.eventNames, contains('store_review_trigger_recorded'));
      expect(analytics.eventNames, contains('store_review_prompt_shown'));
    },
  );

  test('defers automatic review when there are not enough sessions', () async {
    final service = createService();

    await service.registerCurrentSession();
    await service.registerCurrentSession();
    await service.recordTrigger(StoreReviewTrigger.firstGigCreated);

    final result = await service.requestIfEligible();
    final state = await service.debugLoadState('user-1');

    expect(result, StoreReviewAutomaticRequestResult.deferred);
    expect(platformClient.requestReviewCalls, 0);
    expect(state.pendingAutomaticTrigger, StoreReviewTrigger.firstGigCreated);
  });

  test(
    'skips automatic review when already prompted in the current version',
    () async {
      SharedPreferences.setMockInitialValues({
        'store_review.user-1.session_count': 3,
        'store_review.user-1.prompt_count': 1,
        'store_review.user-1.last_prompted_version': '1.5.2+43',
        'store_review.user-1.pending_automatic_trigger':
            StoreReviewTrigger.gigReviewSubmitted.name,
      });
      final service = createService();

      final result = await service.requestIfEligible();
      final state = await service.debugLoadState('user-1');

      expect(result, StoreReviewAutomaticRequestResult.skipped);
      expect(platformClient.requestReviewCalls, 0);
      expect(state.pendingAutomaticTrigger, isNull);
      expect(
        analytics.eventNames.where(
          (name) => name == 'store_review_prompt_skipped',
        ),
        isNotEmpty,
      );
    },
  );

  test('skips automatic review when cooldown is active', () async {
    SharedPreferences.setMockInitialValues({
      'store_review.user-1.session_count': 4,
      'store_review.user-1.last_prompt_at': now
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      'store_review.user-1.pending_automatic_trigger':
          StoreReviewTrigger.firstGigCreated.name,
    });
    final service = createService();

    final result = await service.requestIfEligible();
    final state = await service.debugLoadState('user-1');

    expect(result, StoreReviewAutomaticRequestResult.skipped);
    expect(platformClient.requestReviewCalls, 0);
    expect(state.pendingAutomaticTrigger, isNull);
  });

  test(
    'manual Android flow opens native store listing from settings tap',
    () async {
      final service = createService();

      final result = await service.requestManualReview();
      final state = await service.debugLoadState('user-1');

      expect(result, StoreReviewManualRequestResult.fallbackOpened);
      expect(platformClient.requestReviewCalls, 0);
      expect(platformClient.openStoreListingCalls, 1);
      expect(launchedUris, isEmpty);
      expect(state.lastPromptedVersion, '1.5.2+43');
      expect(analytics.eventNames, contains('store_review_manual_tap'));
      expect(analytics.eventNames, contains('store_review_fallback_opened'));
    },
  );

  test(
    'manual Android flow falls back to Play Store URL when native listing fails',
    () async {
      platformClient.openStoreListingError = Exception('native listing failed');
      final service = createService();

      final result = await service.requestManualReview();

      expect(result, StoreReviewManualRequestResult.fallbackOpened);
      expect(platformClient.openStoreListingCalls, 1);
      expect(launchedUris, <Uri>[
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.mube.mubeoficial',
        ),
      ]);
    },
  );

  test(
    'manual Android flow returns launchFailed when URL fallback throws',
    () async {
      platformClient.openStoreListingError = Exception('native listing failed');
      final service = createService(
        urlLaunchError: Exception('fallback launch failed'),
      );

      final result = await service.requestManualReview();

      expect(result, StoreReviewManualRequestResult.launchFailed);
      expect(platformClient.openStoreListingCalls, 1);
      expect(launchedUris, <Uri>[
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.mube.mubeoficial',
        ),
      ]);
      expect(analytics.eventNames, contains('store_review_prompt_skipped'));
    },
  );

  test('manual iOS flow stays unavailable without an App Store ID', () async {
    final service = createService(platform: TargetPlatform.iOS);

    final result = await service.requestManualReview();

    expect(result, StoreReviewManualRequestResult.unavailable);
    expect(platformClient.openStoreListingCalls, 0);
    expect(launchedUris, isEmpty);
    expect(analytics.eventNames, contains('store_review_manual_tap'));
    expect(analytics.eventNames, contains('store_review_prompt_skipped'));
  });

  test(
    'manual iOS flow opens native App Store review page when App Store ID exists',
    () async {
      final service = createService(
        platform: TargetPlatform.iOS,
        iosAppStoreId: '6741443354',
      );

      final result = await service.requestManualReview();
      final state = await service.debugLoadState('user-1');

      expect(result, StoreReviewManualRequestResult.fallbackOpened);
      expect(platformClient.openStoreListingCalls, 1);
      expect(platformClient.lastAppStoreId, '6741443354');
      expect(launchedUris, isEmpty);
      expect(state.lastPromptedVersion, '1.5.2+43');
      expect(analytics.eventNames, contains('store_review_manual_tap'));
      expect(analytics.eventNames, contains('store_review_fallback_opened'));
    },
  );
}

class _FakeStoreReviewPlatformClient implements StoreReviewPlatformClient {
  bool isAvailableResult = true;
  int requestReviewCalls = 0;
  int openStoreListingCalls = 0;
  String? lastAppStoreId;
  Object? openStoreListingError;

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Future<void> requestReview() async {
    requestReviewCalls += 1;
  }

  @override
  Future<void> openStoreListing({String? appStoreId}) async {
    openStoreListingCalls += 1;
    lastAppStoreId = appStoreId;
    if (openStoreListingError != null) {
      throw openStoreListingError!;
    }
  }
}

class _RecordingAnalyticsService implements AnalyticsService {
  final List<String> eventNames = <String>[];

  @override
  Future<void> logAuthSignupComplete({required String method}) async {}

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    eventNames.add(name);
  }

  @override
  Future<void> logFeedPostView({required String postId}) async {}

  @override
  Future<void> logMatchPointFilter({
    required List<String> instruments,
    required List<String> genres,
    required double distance,
  }) async {}

  @override
  Future<void> logProfileEdit({required String userId}) async {}

  @override
  NavigatorObserver getObserver() => NavigatorObserver();

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}
