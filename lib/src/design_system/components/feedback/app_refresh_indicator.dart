import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';

/// A standardized RefreshIndicator wrapper for the app.
///
/// Uses primary color for the indicator and ensures consistent
/// styling across all screens with pull-to-refresh functionality.
class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  /// Optional edge offset for sliver-based layouts
  final double edgeOffset;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.edgeOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.brandPrimary,
      backgroundColor: AppColors.surface,
      displacement: 60,
      edgeOffset: edgeOffset,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
