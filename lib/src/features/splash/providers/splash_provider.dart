import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashFinishedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void finish() {
    state = true;
  }
}

final splashFinishedProvider = NotifierProvider<SplashFinishedNotifier, bool>(
  SplashFinishedNotifier.new,
);
