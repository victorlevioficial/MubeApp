import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Interface for Analytics Service to allow mocking
abstract class AnalyticsService {
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  Future<void> logScreenView({required String screenName, String? screenClass});

  Future<void> setUserProperty({required String name, required String? value});

  Future<void> setUserId(String? id);

  FirebaseAnalyticsObserver getObserver();

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

class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsService(this._analytics);

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      final normalized = _normalizeParameters(parameters);
      await _analytics.logEvent(name: name, parameters: normalized);
      debugPrint('📊 Analytics Event: $name, params: $normalized');
    } catch (e) {
      debugPrint('❌ Analytics Error: $e');
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
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  @override
  FirebaseAnalyticsObserver getObserver() {
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
