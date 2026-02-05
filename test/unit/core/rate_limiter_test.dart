import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/utils/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter(
        maxRequests: 5,
        windowDuration: const Duration(seconds: 10),
      );
    });

    tearDown(() {
      rateLimiter.clear();
    });

    test('should allow requests within limit', () {
      expect(rateLimiter.allowRequest('user1'), isTrue);
      expect(rateLimiter.allowRequest('user1'), isTrue);
      expect(rateLimiter.allowRequest('user1'), isTrue);
      expect(rateLimiter.allowRequest('user1'), isTrue);
      expect(rateLimiter.allowRequest('user1'), isTrue);
    });

    test('should block requests over limit', () {
      // Use up all requests
      for (var i = 0; i < 5; i++) {
        rateLimiter.allowRequest('user1');
      }

      // 6th request should be blocked
      expect(rateLimiter.allowRequest('user1'), isFalse);
    });

    test('should track different keys independently', () {
      // User 1 uses all requests
      for (var i = 0; i < 5; i++) {
        rateLimiter.allowRequest('user1');
      }
      expect(rateLimiter.allowRequest('user1'), isFalse);

      // User 2 should still be able to make requests
      expect(rateLimiter.allowRequest('user2'), isTrue);
      expect(rateLimiter.allowRequest('user2'), isTrue);
    });

    test('should report correct remaining requests', () {
      expect(rateLimiter.remainingRequests('user1'), 5);

      rateLimiter.allowRequest('user1');
      expect(rateLimiter.remainingRequests('user1'), 4);

      rateLimiter.allowRequest('user1');
      expect(rateLimiter.remainingRequests('user1'), 3);
    });

    test('should return zero remaining when limit reached', () {
      for (var i = 0; i < 5; i++) {
        rateLimiter.allowRequest('user1');
      }

      expect(rateLimiter.remainingRequests('user1'), 0);
    });

    test('should return time until next request when limited', () {
      for (var i = 0; i < 5; i++) {
        rateLimiter.allowRequest('user1');
      }

      final timeUntil = rateLimiter.timeUntilNextRequest('user1');
      expect(timeUntil, isNotNull);
      expect(timeUntil!.inSeconds, greaterThan(0));
      expect(timeUntil.inSeconds, lessThanOrEqualTo(10));
    });

    test('should return zero duration when not limited', () {
      expect(rateLimiter.timeUntilNextRequest('user1'), Duration.zero);
    });

    test('should clear specific key', () {
      for (var i = 0; i < 5; i++) {
        rateLimiter.allowRequest('user1');
      }
      expect(rateLimiter.allowRequest('user1'), isFalse);

      rateLimiter.clearKey('user1');
      expect(rateLimiter.allowRequest('user1'), isTrue);
    });

    test('should clear all keys', () {
      rateLimiter.allowRequest('user1');
      rateLimiter.allowRequest('user2');

      rateLimiter.clear();

      expect(rateLimiter.remainingRequests('user1'), 5);
      expect(rateLimiter.remainingRequests('user2'), 5);
    });
  });

  group('RateLimitConfigs', () {
    test('search config should have correct limits', () {
      final limiter = RateLimitConfigs.search;
      expect(limiter.maxRequests, 30);
      expect(limiter.windowDuration, const Duration(minutes: 1));
    });

    test('apiCalls config should have correct limits', () {
      final limiter = RateLimitConfigs.apiCalls;
      expect(limiter.maxRequests, 100);
      expect(limiter.windowDuration, const Duration(minutes: 1));
    });

    test('uploads config should have correct limits', () {
      final limiter = RateLimitConfigs.uploads;
      expect(limiter.maxRequests, 10);
      expect(limiter.windowDuration, const Duration(minutes: 1));
    });

    test('chatMessages config should have correct limits', () {
      final limiter = RateLimitConfigs.chatMessages;
      expect(limiter.maxRequests, 60);
      expect(limiter.windowDuration, const Duration(minutes: 1));
    });

    test('matchpointSwipes config should have correct limits', () {
      final limiter = RateLimitConfigs.matchpointSwipes;
      expect(limiter.maxRequests, 50);
      expect(limiter.windowDuration, const Duration(minutes: 1));
    });

    test('loginAttempts config should have correct limits', () {
      final limiter = RateLimitConfigs.loginAttempts;
      expect(limiter.maxRequests, 5);
      expect(limiter.windowDuration, const Duration(minutes: 5));
    });
  });
}
