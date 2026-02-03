import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_icons.dart';

/// Reusable back button following design system.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        AppIcons.arrowBack,
        color: AppColors.textPrimary,
        size: 20,
      ),
      onPressed: onPressed ?? () => context.pop(),
      tooltip: 'Voltar',
    );
  }
}
