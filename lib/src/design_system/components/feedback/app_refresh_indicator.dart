import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';

/// A standardized RefreshIndicator wrapper for the app.
///
/// Uses primary color for the indicator and ensures consistent
/// styling across all screens with pull-to-refresh functionality.
///
/// Pair this with [defaultScrollPhysics] on the wrapped scrollable so the
/// gesture also works when content is shorter than the viewport.
class AppRefreshIndicator extends StatelessWidget {
  static const ScrollPhysics defaultScrollPhysics =
      AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());

  final Widget child;
  final Future<void> Function() onRefresh;

  /// Optional edge offset for sliver-based layouts
  final double edgeOffset;
  final ScrollNotificationPredicate notificationPredicate;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.edgeOffset = 0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      displacement: 60,
      edgeOffset: edgeOffset,
      notificationPredicate: notificationPredicate,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
