import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_logger.dart';

abstract class MetaAnalyticsService {
  Future<void> initialize();
  Future<void> setUserId(String? userId);
  Future<void> logCompletedRegistration({String method = 'email'});
  Future<void> logCompletedProfile({required String profileType});
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  });
}

class NoopMetaAnalyticsService implements MetaAnalyticsService {
  const NoopMetaAnalyticsService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> logCompletedRegistration({String method = 'email'}) async {}

  @override
  Future<void> logCompletedProfile({required String profileType}) async {}

  @override
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {}
}

class FacebookMetaAnalyticsService implements MetaAnalyticsService {
  FacebookMetaAnalyticsService([FacebookAppEvents? client])
    : _client = client ?? FacebookAppEvents();

  final FacebookAppEvents _client;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Platform.isIOS) {
        await _requestTrackingAuthorization();
      }
      await _client.setAdvertiserTracking(enabled: true);
      await _client.setAutoLogAppEventsEnabled(true);
      AppLogger.info('MetaAnalytics initialized');
    } catch (e, stack) {
      AppLogger.warning('MetaAnalytics initialize failed', e, stack);
    }
  }

  Future<void> _requestTrackingAuthorization() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e, stack) {
      AppLogger.warning('ATT request failed', e, stack);
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      if (userId == null || userId.isEmpty) {
        await _client.clearUserID();
      } else {
        await _client.setUserID(userId);
      }
    } catch (e, stack) {
      AppLogger.warning('MetaAnalytics setUserId failed', e, stack);
    }
  }

  @override
  Future<void> logCompletedRegistration({String method = 'email'}) async {
    try {
      await _client.logEvent(
        name: 'fb_mobile_complete_registration',
        parameters: {'fb_registration_method': method},
      );
    } catch (e, stack) {
      AppLogger.warning('MetaAnalytics signup event failed', e, stack);
    }
  }

  @override
  Future<void> logCompletedProfile({required String profileType}) async {
    try {
      await _client.logEvent(
        name: 'mube_profile_complete',
        parameters: {'profile_type': profileType},
      );
    } catch (e, stack) {
      AppLogger.warning('MetaAnalytics profile complete failed', e, stack);
    }
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _client.logEvent(name: name, parameters: parameters);
    } catch (e, stack) {
      AppLogger.warning('MetaAnalytics event failed: $name', e, stack);
    }
  }
}

final metaAnalyticsServiceProvider = Provider<MetaAnalyticsService>((ref) {
  if (kIsWeb) return const NoopMetaAnalyticsService();
  if (!Platform.isAndroid && !Platform.isIOS) {
    return const NoopMetaAnalyticsService();
  }
  return FacebookMetaAnalyticsService();
});
