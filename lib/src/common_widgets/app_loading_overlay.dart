import 'package:flutter/material.dart';
import 'app_loading.dart';

/// A full-screen loading overlay that blocks user interaction.
///
/// Use this for operations that require the user to wait, such as:
/// - Authentication (login/register)
/// - Data submission
/// - Critical updates
///
/// Example:
/// ```dart
/// AppLoadingOverlay.show(context, message: 'Entrando...');
/// // ... async operation
/// AppLoadingOverlay.hide(context);
/// ```
class AppLoadingOverlay extends StatelessWidget {
  final String? message;

  const AppLoadingOverlay({super.key, this.message});

  /// Shows the loading overlay as a modal dialog.
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => AppLoadingOverlay(message: message),
    );
  }

  /// Hides the currently showing loading overlay.
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppLoading.large(message: message),
        ),
      ),
    );
  }
}
