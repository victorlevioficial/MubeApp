import 'package:flutter/material.dart';

import '../design_system/foundations/app_radius.dart';
import '../design_system/foundations/app_spacing.dart';

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all12,
          side: BorderSide(
            color: isError
                ? Theme.of(context).colorScheme.error.withOpacity(0.5)
                : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        margin: AppSpacing.all16,
        elevation: 4,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
