import 'package:flutter/material.dart';

import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_typography.dart';

/// Standardized AppBar for the Mube app.
///
/// Use this component instead of [AppBar] to ensure consistent styling
/// across all screens, including:
/// - Correct back arrow icon (iOS-style chevron)
/// - Proper text colors
/// - Consistent background
///
/// Example:
/// ```dart
/// Scaffold(
///   appBar: MubeAppBar(title: 'Minha Tela'),
///   body: ...,
/// )
/// ```
class MubeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title text or widget to display.
  final dynamic title;

  /// Optional list of action widgets (right side of AppBar).
  final List<Widget>? actions;

  /// Whether to show the back button. Defaults to true if Navigator can pop.
  final bool? showBackButton;

  /// Custom callback for back button. If null, uses Navigator.pop().
  final VoidCallback? onBackPressed;

  /// Whether to center the title. Defaults to true.
  final bool centerTitle;

  /// Optional bottom widget (e.g., TabBar).
  final PreferredSizeWidget? bottom;

  const MubeAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton,
    this.onBackPressed,
    this.centerTitle = true,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton ?? canPop;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: shouldShowBack
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: title is String
          ? Text(
              title as String,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            )
          : (title as Widget?),
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
    );
  }
}
