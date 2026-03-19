import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../utils/app_logger.dart';
import '../providers/firebase_providers.dart';
import 'analytics/analytics_provider.dart';
import 'analytics/analytics_service.dart';

typedef CurrentUserUidLoader = String? Function();
typedef StoreReviewPackageInfoLoader = Future<PackageInfo> Function();
typedef StoreReviewUrlLauncher = Future<bool> Function(Uri uri);
typedef StoreReviewClock = DateTime Function();
typedef StoreReviewPlatformResolver = TargetPlatform Function();

const String kMubeIosAppStoreId = '6741443354';

enum StoreReviewTrigger {
  gigReviewSubmitted,
  firstGigCreated,
  manualSettingsTap,
}

extension StoreReviewTriggerX on StoreReviewTrigger {
  String get analyticsValue {
    switch (this) {
      case StoreReviewTrigger.gigReviewSubmitted:
        return 'gig_review_submitted';
      case StoreReviewTrigger.firstGigCreated:
        return 'first_gig_created';
      case StoreReviewTrigger.manualSettingsTap:
        return 'manual_settings_tap';
    }
  }
}

enum StoreReviewManualRequestResult {
  promptRequested,
  fallbackOpened,
  unavailable,
  launchFailed,
}

enum StoreReviewAutomaticRequestResult { prompted, deferred, skipped, noAction }

abstract class StoreReviewPlatformClient {
  Future<bool> isAvailable();

  Future<void> requestReview();
}

class InAppReviewPlatformClient implements StoreReviewPlatformClient {
  InAppReviewPlatformClient(this._inAppReview);

  final InAppReview _inAppReview;

  @override
  Future<bool> isAvailable() => _inAppReview.isAvailable();

  @override
  Future<void> requestReview() => _inAppReview.requestReview();
}

@immutable
class StoreReviewState {
  const StoreReviewState({
    this.firstSeenAt,
    this.lastPromptAt,
    this.lastPromptedVersion,
    this.pendingAutomaticTrigger,
    this.promptCount = 0,
    this.sessionCount = 0,
  });

  final DateTime? firstSeenAt;
  final DateTime? lastPromptAt;
  final String? lastPromptedVersion;
  final StoreReviewTrigger? pendingAutomaticTrigger;
  final int promptCount;
  final int sessionCount;

  StoreReviewState copyWith({
    DateTime? firstSeenAt,
    DateTime? lastPromptAt,
    String? lastPromptedVersion,
    bool clearLastPromptedVersion = false,
    StoreReviewTrigger? pendingAutomaticTrigger,
    bool clearPendingAutomaticTrigger = false,
    int? promptCount,
    int? sessionCount,
  }) {
    return StoreReviewState(
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastPromptAt: lastPromptAt ?? this.lastPromptAt,
      lastPromptedVersion: clearLastPromptedVersion
          ? null
          : lastPromptedVersion ?? this.lastPromptedVersion,
      pendingAutomaticTrigger: clearPendingAutomaticTrigger
          ? null
          : pendingAutomaticTrigger ?? this.pendingAutomaticTrigger,
      promptCount: promptCount ?? this.promptCount,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }
}

class StoreReviewService {
  StoreReviewService({
    required CurrentUserUidLoader currentUserUidLoader,
    required AnalyticsService analytics,
    required SharedPreferencesLoader sharedPreferencesLoader,
    required StoreReviewPackageInfoLoader packageInfoLoader,
    required StoreReviewPlatformClient platformClient,
    required StoreReviewUrlLauncher urlLauncher,
    required StoreReviewClock clock,
    required StoreReviewPlatformResolver platformResolver,
    String? iosAppStoreId,
  }) : _currentUserUidLoader = currentUserUidLoader,
       _analytics = analytics,
       _sharedPreferencesLoader = sharedPreferencesLoader,
       _packageInfoLoader = packageInfoLoader,
       _platformClient = platformClient,
       _urlLauncher = urlLauncher,
       _clock = clock,
       _platformResolver = platformResolver,
       _iosAppStoreId = iosAppStoreId?.trim();

  static const int automaticMinimumSessions = 3;
  static const Duration automaticCooldown = Duration(days: 90);
  static final Uri _androidStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.mube.mubeoficial',
  );

  final CurrentUserUidLoader _currentUserUidLoader;
  final AnalyticsService _analytics;
  final SharedPreferencesLoader _sharedPreferencesLoader;
  final StoreReviewPackageInfoLoader _packageInfoLoader;
  final StoreReviewPlatformClient _platformClient;
  final StoreReviewUrlLauncher _urlLauncher;
  final StoreReviewClock _clock;
  final StoreReviewPlatformResolver _platformResolver;
  final String? _iosAppStoreId;

  Future<void> registerCurrentSession() async {
    final uid = _currentUserUidLoader();
    if (uid == null || uid.isEmpty) {
      return;
    }

    final prefs = await _sharedPreferencesLoader();
    final state = _readState(prefs, uid);
    final now = _clock();
    final updatedState = state.copyWith(
      firstSeenAt: state.firstSeenAt ?? now,
      sessionCount: state.sessionCount + 1,
    );
    await _writeState(prefs, uid, updatedState);
  }

  Future<void> recordTrigger(StoreReviewTrigger trigger) async {
    final uid = _currentUserUidLoader();
    if (uid == null || uid.isEmpty) {
      return;
    }

    final prefs = await _sharedPreferencesLoader();
    final state = _readState(prefs, uid);
    final updatedState = trigger == StoreReviewTrigger.manualSettingsTap
        ? state
        : state.copyWith(pendingAutomaticTrigger: trigger);
    await _writeState(prefs, uid, updatedState);

    await _analytics.logEvent(
      name: 'store_review_trigger_recorded',
      parameters: {
        'trigger': trigger.analyticsValue,
        'session_count': updatedState.sessionCount,
      },
    );
  }

  Future<StoreReviewAutomaticRequestResult> requestIfEligible() async {
    final uid = _currentUserUidLoader();
    if (uid == null || uid.isEmpty) {
      return StoreReviewAutomaticRequestResult.noAction;
    }

    final prefs = await _sharedPreferencesLoader();
    final state = _readState(prefs, uid);
    final pendingTrigger = state.pendingAutomaticTrigger;
    if (pendingTrigger == null) {
      return StoreReviewAutomaticRequestResult.noAction;
    }

    if (state.sessionCount < automaticMinimumSessions) {
      return StoreReviewAutomaticRequestResult.deferred;
    }

    final currentVersion = await _loadCurrentVersionLabel();
    final now = _clock();

    if (state.lastPromptedVersion == currentVersion) {
      await _writeState(
        prefs,
        uid,
        state.copyWith(clearPendingAutomaticTrigger: true),
      );
      await _logPromptSkipped(
        reason: 'already_prompted_this_version',
        source: 'automatic',
        trigger: pendingTrigger,
      );
      return StoreReviewAutomaticRequestResult.skipped;
    }

    if (state.lastPromptAt != null &&
        now.difference(state.lastPromptAt!) < automaticCooldown) {
      await _writeState(
        prefs,
        uid,
        state.copyWith(clearPendingAutomaticTrigger: true),
      );
      await _logPromptSkipped(
        reason: 'cooldown_active',
        source: 'automatic',
        trigger: pendingTrigger,
      );
      return StoreReviewAutomaticRequestResult.skipped;
    }

    final isAvailable = await _platformClient.isAvailable();
    if (!isAvailable) {
      await _writeState(
        prefs,
        uid,
        state.copyWith(clearPendingAutomaticTrigger: true),
      );
      await _logPromptSkipped(
        reason: 'prompt_unavailable',
        source: 'automatic',
        trigger: pendingTrigger,
      );
      return StoreReviewAutomaticRequestResult.skipped;
    }

    try {
      await _platformClient.requestReview();
      await _writeState(
        prefs,
        uid,
        state.copyWith(
          lastPromptAt: now,
          lastPromptedVersion: currentVersion,
          clearPendingAutomaticTrigger: true,
          promptCount: state.promptCount + 1,
        ),
      );
      await _analytics.logEvent(
        name: 'store_review_prompt_shown',
        parameters: {
          'source': 'automatic',
          'trigger': pendingTrigger.analyticsValue,
        },
      );
      return StoreReviewAutomaticRequestResult.prompted;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to request automatic store review',
        error,
        stackTrace,
      );
      await _writeState(
        prefs,
        uid,
        state.copyWith(clearPendingAutomaticTrigger: true),
      );
      await _logPromptSkipped(
        reason: 'request_failed',
        source: 'automatic',
        trigger: pendingTrigger,
      );
      return StoreReviewAutomaticRequestResult.skipped;
    }
  }

  Future<StoreReviewManualRequestResult> requestManualReview() async {
    final uid = _currentUserUidLoader();
    final state = uid == null || uid.isEmpty
        ? const StoreReviewState()
        : _readState(await _sharedPreferencesLoader(), uid);
    final currentVersion = await _loadCurrentVersionLabel();
    final now = _clock();

    await _analytics.logEvent(
      name: 'store_review_manual_tap',
      parameters: {'authenticated': uid == null || uid.isEmpty ? 0 : 1},
    );

    try {
      final isAvailable = await _platformClient.isAvailable();
      if (isAvailable) {
        await _platformClient.requestReview();
        if (uid != null && uid.isNotEmpty) {
          final prefs = await _sharedPreferencesLoader();
          await _writeState(
            prefs,
            uid,
            state.copyWith(
              lastPromptAt: now,
              lastPromptedVersion: currentVersion,
              promptCount: state.promptCount + 1,
            ),
          );
        }
        await _analytics.logEvent(
          name: 'store_review_prompt_shown',
          parameters: {'source': 'manual'},
        );
        return StoreReviewManualRequestResult.promptRequested;
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to request manual store review',
        error,
        stackTrace,
      );
    }

    final fallbackUri = _fallbackStoreUri();
    if (fallbackUri == null) {
      await _logPromptSkipped(reason: 'manual_unavailable', source: 'manual');
      return StoreReviewManualRequestResult.unavailable;
    }

    final launched = await _urlLauncher(fallbackUri);
    if (!launched) {
      await _logPromptSkipped(
        reason: 'fallback_launch_failed',
        source: 'manual',
      );
      return StoreReviewManualRequestResult.launchFailed;
    }

    if (uid != null && uid.isNotEmpty) {
      final prefs = await _sharedPreferencesLoader();
      await _writeState(
        prefs,
        uid,
        state.copyWith(lastPromptAt: now, lastPromptedVersion: currentVersion),
      );
    }

    await _analytics.logEvent(
      name: 'store_review_fallback_opened',
      parameters: {'platform': _platformResolver().name, 'source': 'manual'},
    );
    return StoreReviewManualRequestResult.fallbackOpened;
  }

  @visibleForTesting
  Future<StoreReviewState> debugLoadState(String uid) async {
    final prefs = await _sharedPreferencesLoader();
    return _readState(prefs, uid);
  }

  Future<void> _logPromptSkipped({
    required String reason,
    required String source,
    StoreReviewTrigger? trigger,
  }) {
    return _analytics.logEvent(
      name: 'store_review_prompt_skipped',
      parameters: {
        'reason': reason,
        'source': source,
        if (trigger != null) 'trigger': trigger.analyticsValue,
      },
    );
  }

  Future<String> _loadCurrentVersionLabel() async {
    final packageInfo = await _packageInfoLoader();
    final version = packageInfo.version.trim();
    final buildNumber = packageInfo.buildNumber.trim();
    if (buildNumber.isEmpty) {
      return version;
    }
    return '$version+$buildNumber';
  }

  Uri? _fallbackStoreUri() {
    switch (_platformResolver()) {
      case TargetPlatform.android:
        return _androidStoreUri;
      case TargetPlatform.iOS:
        final appStoreId = _iosAppStoreId;
        if (appStoreId == null || appStoreId.isEmpty) {
          return null;
        }
        return Uri.parse(
          'https://apps.apple.com/app/id$appStoreId?action=write-review',
        );
      default:
        return null;
    }
  }

  StoreReviewState _readState(SharedPreferences prefs, String uid) {
    final prefix = _stateKeyPrefix(uid);
    return StoreReviewState(
      firstSeenAt: _readDateTime(prefs.getInt('${prefix}first_seen_at')),
      lastPromptAt: _readDateTime(prefs.getInt('${prefix}last_prompt_at')),
      lastPromptedVersion: prefs.getString('${prefix}last_prompted_version'),
      pendingAutomaticTrigger: _readTrigger(
        prefs.getString('${prefix}pending_automatic_trigger'),
      ),
      promptCount: prefs.getInt('${prefix}prompt_count') ?? 0,
      sessionCount: prefs.getInt('${prefix}session_count') ?? 0,
    );
  }

  Future<void> _writeState(
    SharedPreferences prefs,
    String uid,
    StoreReviewState state,
  ) async {
    final prefix = _stateKeyPrefix(uid);
    await prefs.setInt('${prefix}session_count', state.sessionCount);
    await prefs.setInt('${prefix}prompt_count', state.promptCount);

    final firstSeenAt = state.firstSeenAt;
    if (firstSeenAt == null) {
      await prefs.remove('${prefix}first_seen_at');
    } else {
      await prefs.setInt(
        '${prefix}first_seen_at',
        firstSeenAt.millisecondsSinceEpoch,
      );
    }

    final lastPromptAt = state.lastPromptAt;
    if (lastPromptAt == null) {
      await prefs.remove('${prefix}last_prompt_at');
    } else {
      await prefs.setInt(
        '${prefix}last_prompt_at',
        lastPromptAt.millisecondsSinceEpoch,
      );
    }

    final lastPromptedVersion = state.lastPromptedVersion?.trim();
    if (lastPromptedVersion == null || lastPromptedVersion.isEmpty) {
      await prefs.remove('${prefix}last_prompted_version');
    } else {
      await prefs.setString(
        '${prefix}last_prompted_version',
        lastPromptedVersion,
      );
    }

    final pendingAutomaticTrigger = state.pendingAutomaticTrigger;
    if (pendingAutomaticTrigger == null) {
      await prefs.remove('${prefix}pending_automatic_trigger');
    } else {
      await prefs.setString(
        '${prefix}pending_automatic_trigger',
        pendingAutomaticTrigger.name,
      );
    }
  }

  DateTime? _readDateTime(int? millisecondsSinceEpoch) {
    if (millisecondsSinceEpoch == null || millisecondsSinceEpoch <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }

  StoreReviewTrigger? _readTrigger(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    for (final trigger in StoreReviewTrigger.values) {
      if (trigger.name == rawValue) {
        return trigger;
      }
    }

    return null;
  }

  String _stateKeyPrefix(String uid) => 'store_review.$uid.';
}

final storeReviewServiceProvider = Provider<StoreReviewService>((ref) {
  AnalyticsService analytics;
  try {
    analytics = ref.read(analyticsServiceProvider);
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Store review analytics unavailable; falling back to noop analytics',
      error,
      stackTrace,
    );
    analytics = const NoopAnalyticsService();
  }

  return StoreReviewService(
    currentUserUidLoader: () =>
        ref.read(authRepositoryProvider).currentUser?.uid,
    analytics: analytics,
    sharedPreferencesLoader: ref.read(sharedPreferencesLoaderProvider),
    packageInfoLoader: PackageInfo.fromPlatform,
    platformClient: InAppReviewPlatformClient(InAppReview.instance),
    urlLauncher: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
    clock: DateTime.now,
    platformResolver: () => defaultTargetPlatform,
    iosAppStoreId: kMubeIosAppStoreId,
  );
});
