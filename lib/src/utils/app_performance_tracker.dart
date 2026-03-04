import 'app_logger.dart';

/// Lightweight runtime performance markers for local profiling sessions.
final class AppPerformanceTracker {
  AppPerformanceTracker._();

  static final Stopwatch _appUptime = Stopwatch()..start();

  static Stopwatch startSpan(String label, {Map<String, Object?>? data}) {
    mark('$label.start', data: data);
    return Stopwatch()..start();
  }

  static void finishSpan(
    String label,
    Stopwatch stopwatch, {
    Map<String, Object?>? data,
  }) {
    if (!stopwatch.isRunning) {
      mark(
        '$label.finish',
        data: {'duration_ms': stopwatch.elapsedMilliseconds, ...?data},
      );
      return;
    }

    stopwatch.stop();
    mark(
      '$label.finish',
      data: {'duration_ms': stopwatch.elapsedMilliseconds, ...?data},
    );
  }

  static void mark(String label, {Map<String, Object?>? data}) {
    final payload = StringBuffer(
      '[Perf] +${_appUptime.elapsedMilliseconds}ms ',
    );
    payload.write(label);

    final normalizedData = _normalizeData(data);
    if (normalizedData.isNotEmpty) {
      payload.write(' | ');
      payload.write(
        normalizedData.entries
            .map((entry) {
              return '${entry.key}=${entry.value}';
            })
            .join(' '),
      );
    }

    AppLogger.debug(payload.toString());
  }

  static Map<String, Object> _normalizeData(Map<String, Object?>? data) {
    if (data == null || data.isEmpty) return const {};

    final normalized = <String, Object>{};
    data.forEach((key, value) {
      if (value == null) return;
      normalized[key] = value is Enum ? value.name : value;
    });
    return normalized;
  }
}
