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
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('📊 Analytics Event: $name, params: $parameters');
    } catch (e) {
      debugPrint('❌ Analytics Error: $e');
    }
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
