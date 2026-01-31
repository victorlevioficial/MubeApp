import 'package:flutter/material.dart';

import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_spacing.dart';
import '../design_system/foundations/app_typography.dart';

/// A reusable empty state widget for showing when lists/feeds are empty.
///
/// Used in Feed (no results), Favorites (empty), Search (no matches), etc.
/// Features a subtle fade + scale entrance animation for polish.
class EmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? actionButton;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionButton,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s32,
              vertical: AppSpacing.s48,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with subtle background
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 40,
                    color: AppColors.textTertiary,
                  ),
                ),

                const SizedBox(height: AppSpacing.s24),

                // Title
                Text(
                  widget.title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Subtitle
                if (widget.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    widget.subtitle!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Action button
                if (widget.actionButton != null) ...[
                  const SizedBox(height: AppSpacing.s24),
                  widget.actionButton!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
