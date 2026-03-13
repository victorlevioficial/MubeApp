import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight =
                constraints.maxHeight.isFinite && constraints.maxHeight < 320;
            final iconContainerSize = isCompactHeight ? 64.0 : 80.0;
            final iconSize = isCompactHeight ? 32.0 : 40.0;
            final verticalPadding = isCompactHeight
                ? AppSpacing.s24
                : AppSpacing.s48;
            final sectionSpacing = isCompactHeight
                ? AppSpacing.s16
                : AppSpacing.s24;

            final content = Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s32,
                  vertical: verticalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Allow empty states to scale down on short heights,
                    // such as when the keyboard is open.
                    Container(
                      width: iconContainerSize,
                      height: iconContainerSize,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: iconSize,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    Text(
                      widget.title,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
                    if (widget.actionButton != null) ...[
                      SizedBox(height: sectionSpacing),
                      widget.actionButton!,
                    ],
                  ],
                ),
              ),
            );

            return SingleChildScrollView(
              child: constraints.maxHeight.isFinite
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: content,
                    )
                  : content,
            );
          },
        ),
      ),
    );
  }
}
