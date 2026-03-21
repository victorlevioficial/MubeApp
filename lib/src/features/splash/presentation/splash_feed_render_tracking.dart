import '../../../utils/app_performance_tracker.dart';

final class SplashFeedRenderTracking {
  SplashFeedRenderTracking._();

  static Stopwatch? _stopwatch;
  static bool _started = false;
  static bool _finished = false;

  static void startSplashToFeedRenderTracking() {
    if (_started) return;
    _started = true;
    _finished = false;
    _stopwatch = AppPerformanceTracker.startSpan('app.splash_to_feed_render');
  }

  static void finishSplashToFeedRenderTracking({Map<String, Object?>? data}) {
    if (_finished) return;
    _finished = true;

    final stopwatch = _stopwatch;
    if (stopwatch == null) {
      final fallbackStopwatch = AppPerformanceTracker.startSpan(
        'app.splash_to_feed_render',
      );
      AppPerformanceTracker.finishSpan(
        'app.splash_to_feed_render',
        fallbackStopwatch,
        data: data,
      );
      return;
    }

    AppPerformanceTracker.finishSpan(
      'app.splash_to_feed_render',
      stopwatch,
      data: data,
    );
  }
}

void startSplashToFeedRenderTracking() {
  SplashFeedRenderTracking.startSplashToFeedRenderTracking();
}

void finishSplashToFeedRenderTracking({Map<String, Object?>? data}) {
  SplashFeedRenderTracking.finishSplashToFeedRenderTracking(data: data);
}
