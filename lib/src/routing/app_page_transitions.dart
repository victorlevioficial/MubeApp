import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Slide-in from right transition for detail/push routes.
CustomTransitionPage<void> slideTransitionPage({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
  Duration reverseDuration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
    },
  );
}

/// Fade transition for overlay-style routes.
CustomTransitionPage<void> fadeTransitionPage({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      );
    },
  );
}
