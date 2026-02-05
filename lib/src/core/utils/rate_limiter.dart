import 'dart:collection';

/// Rate limiter implementation for API calls and user actions.
///
/// Use this to prevent abuse of APIs and limit user actions
/// like searches, uploads, or API calls.
///
/// Example:
/// ```dart
/// final rateLimiter = RateLimiter(
///   maxRequests: 10,
///   windowDuration: Duration(minutes: 1),
/// );
///
/// if (rateLimiter.allowRequest('user_123')) {
///   // Perform the action
/// } else {
///   // Show error: Rate limit exceeded
/// }
/// ```
class RateLimiter {
  final int maxRequests;
  final Duration windowDuration;
  final Map<String, Queue<DateTime>> _requests = {};

  RateLimiter({
    required this.maxRequests,
    required this.windowDuration,
  });

  /// Checks if a request is allowed for the given key.
  /// Returns true if the request is within the rate limit.
  bool allowRequest(String key) {
    final now = DateTime.now();
    final windowStart = now.subtract(windowDuration);

    // Get or create request queue for this key
    final queue = _requests.putIfAbsent(key, () => Queue<DateTime>());

    // Remove old requests outside the window
    while (queue.isNotEmpty && queue.first.isBefore(windowStart)) {
      queue.removeFirst();
    }

    // Check if we're within the limit
    if (queue.length < maxRequests) {
      queue.addLast(now);
      return true;
    }

    return false;
  }

  /// Returns the number of remaining requests for the given key.
  int remainingRequests(String key) {
    final now = DateTime.now();
    final windowStart = now.subtract(windowDuration);

    final queue = _requests[key];
    if (queue == null) return maxRequests;

    // Remove old requests
    while (queue.isNotEmpty && queue.first.isBefore(windowStart)) {
      queue.removeFirst();
    }

    return maxRequests - queue.length;
  }

  /// Returns the time until the next request is allowed.
  Duration? timeUntilNextRequest(String key) {
    final now = DateTime.now();
    final windowStart = now.subtract(windowDuration);

    final queue = _requests[key];
    if (queue == null || queue.isEmpty) return Duration.zero;

    // Remove old requests
    while (queue.isNotEmpty && queue.first.isBefore(windowStart)) {
      queue.removeFirst();
    }

    if (queue.length < maxRequests) return Duration.zero;

    // Calculate time until oldest request expires
    final oldestRequest = queue.first;
    final expirationTime = oldestRequest.add(windowDuration);
    return expirationTime.difference(now);
  }

  /// Clears all rate limiting data.
  void clear() {
    _requests.clear();
  }

  /// Clears rate limiting data for a specific key.
  void clearKey(String key) {
    _requests.remove(key);
  }
}

/// Predefined rate limiting configurations for common use cases.
class RateLimitConfigs {
  const RateLimitConfigs._();

  /// For search operations: 30 requests per minute
  static RateLimiter get search => RateLimiter(
        maxRequests: 30,
        windowDuration: const Duration(minutes: 1),
      );

  /// For API calls: 100 requests per minute
  static RateLimiter get apiCalls => RateLimiter(
        maxRequests: 100,
        windowDuration: const Duration(minutes: 1),
      );

  /// For uploads: 10 uploads per minute
  static RateLimiter get uploads => RateLimiter(
        maxRequests: 10,
        windowDuration: const Duration(minutes: 1),
      );

  /// For chat messages: 60 messages per minute
  static RateLimiter get chatMessages => RateLimiter(
        maxRequests: 60,
        windowDuration: const Duration(minutes: 1),
      );

  /// For matchpoint swipes: 50 swipes per minute
  static RateLimiter get matchpointSwipes => RateLimiter(
        maxRequests: 50,
        windowDuration: const Duration(minutes: 1),
      );

  /// For login attempts: 5 attempts per 5 minutes
  static RateLimiter get loginAttempts => RateLimiter(
        maxRequests: 5,
        windowDuration: const Duration(minutes: 5),
      );
}
