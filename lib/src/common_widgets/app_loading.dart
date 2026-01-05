import 'package:flutter/material.dart';
import '../design_system/foundations/app_colors.dart';

/// A themed loading indicator widget for the app.
///
/// Can be used inline (buttons, cards) or as standalone loading feedback.
/// Uses the app's primary color for consistent branding.
class AppLoading extends StatelessWidget {
  /// Optional message to display below the spinner.
  final String? message;

  /// Size of the loading indicator. Defaults to 24.
  final double size;

  /// Stroke width of the circular indicator.
  final double strokeWidth;

  /// Color of the indicator. Defaults to primary color.
  final Color? color;

  const AppLoading({
    super.key,
    this.message,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.color,
  });

  /// Small inline loading for buttons.
  const AppLoading.small({super.key, this.color})
    : message = null,
      size = 16,
      strokeWidth = 2;

  /// Medium loading for content areas.
  const AppLoading.medium({super.key, this.message, this.color})
    : size = 32,
      strokeWidth = 3;

  /// Large loading for full-screen overlays.
  const AppLoading.large({super.key, this.message, this.color})
    : size = 48,
      strokeWidth = 4;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
