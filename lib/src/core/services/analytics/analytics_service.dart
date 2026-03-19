import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../utils/app_logger.dart';

/// Interface for Analytics Service to allow mocking
abstract class AnalyticsService {
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  Future<void> logScreenView({required String screenName, String? screenClass});

  Future<void> setUserProperty({required String name, required String? value});

  Future<void> setUserId(String? id);

  NavigatorObserver getObserver();

  // --- Business Specific Events ---

  Future<void> logAuthSignupComplete({required String method});
  Future<void> logMatchPointFilter({
    required List<String> instruments,
    required List<String> genres,
    required double distance,
  });
  Future<void> logFeedPostView({required String postId});
  Future<void> logProfileEdit({required String userId});
}

class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  NavigatorObserver getObserver() => _NoopNavigatorObserver();

  @override
  Future<void> logAuthSignupComplete({required String method}) async {}

  @override
  Future<void> logMatchPointFilter({
    required List<String> instruments,
    required List<String> genres,
    required double distance,
  }) async {}

  @override
  Future<void> logFeedPostView({required String postId}) async {}

  @override
  Future<void> logProfileEdit({required String userId}) async {}
}

class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics;
  final bool _isEnabled;
  static const bool _enableInDebug = bool.fromEnvironment(
    'MUBE_ENABLE_ANALYTICS_IN_DEBUG',
    defaultValue: true,
  );

  FirebaseAnalyticsService(this._analytics)
    : _isEnabled = kReleaseMode || _enableInDebug;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isEnabled) return;

    try {
      final normalized = _normalizeParameters(parameters);
      await _analytics.logEvent(name: name, parameters: normalized);
      AppLogger.debug('Analytics event: $name params=$normalized');
    } catch (e, stackTrace) {
      AppLogger.warning('Analytics event failed: $name', e, stackTrace);
    }
  }

  Map<String, Object>? _normalizeParameters(Map<String, Object>? parameters) {
    if (parameters == null) return null;

    return parameters.map((key, value) {
      if (value is String || value is num) {
        return MapEntry(key, value);
      }

      if (value is bool) {
        return MapEntry(key, value ? 1 : 0);
      }

      return MapEntry(key, value.toString());
    });
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isEnabled) return;

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Analytics screen view failed: $screenName',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_isEnabled) return;

    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Analytics setUserProperty failed: $name',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> setUserId(String? id) async {
    if (!_isEnabled) return;

    try {
      await _analytics.setUserId(id: id);
    } catch (e, stackTrace) {
      AppLogger.warning('Analytics setUserId failed', e, stackTrace);
    }
  }

  @override
  NavigatorObserver getObserver() {
    if (!_isEnabled) {
      return _NoopNavigatorObserver();
    }
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // --- Business Logic Implementations ---

  @override
  Future<void> logAuthSignupComplete({required String method}) async {
    await logEvent(
      name: 'auth_signup_complete',
      parameters: {'method': method},
    );
  }

  @override
  Future<void> logMatchPointFilter({
    required List<String> instruments,
    required List<String> genres,
    required double distance,
  }) async {
    await logEvent(
      name: 'matchpoint_filter',
      parameters: {
        'instruments': instruments.join(','), // Analytics params are primitive
        'genres': genres.join(','),
        'distance': distance,
      },
    );
  }

  @override
  Future<void> logFeedPostView({required String postId}) async {
    await logEvent(name: 'feed_post_view', parameters: {'post_id': postId});
  }

  @override
  Future<void> logProfileEdit({required String userId}) async {
    await logEvent(name: 'profile_edit', parameters: {'user_id': userId});
  }
}

class _NoopNavigatorObserver extends NavigatorObserver {
  _NoopNavigatorObserver();
}
