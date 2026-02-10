import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';

/// Widget de loading centralizado.
@Deprecated('Use AppLoadingIndicator instead. This will be removed in v2.0.0')
class AppLoading extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoading({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.5,
  });

  const AppLoading.small({super.key, this.color})
    : size = 16.0,
      strokeWidth = 2.0;

  const AppLoading.medium({super.key, this.color})
    : size = 24.0,
      strokeWidth = 2.5;

  const AppLoading.large({super.key, this.color})
    : size = 48.0,
      strokeWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
      ),
    );
  }
}
