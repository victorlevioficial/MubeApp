import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashFinishedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void finish() {
    state = true;
  }

  /// Resets the splash gate so the router bounces back through the splash
  /// screen on subsequent evaluations. Used by logout and tests to prevent
  /// stale "ready" state from leaking across auth sessions.
  void reset() {
    state = false;
  }
}

final splashFinishedProvider = NotifierProvider<SplashFinishedNotifier, bool>(
  SplashFinishedNotifier.new,
);
