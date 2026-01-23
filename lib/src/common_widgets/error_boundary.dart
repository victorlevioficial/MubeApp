import 'package:flutter/material.dart';

import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_spacing.dart';
import '../design_system/foundations/app_typography.dart';
import '../utils/app_logger.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? fallbackMessage;

  const ErrorBoundary({super.key, required this.child, this.fallbackMessage});

  // This method builds the standard "Crash Screen"
  static Widget buildErrorWidget(FlutterErrorDetails details) {
    AppLogger.error('UI Error Caught', details.exception, details.stack);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 64),
              const SizedBox(height: AppSpacing.s24),
              Text(
                'Ops! Algo deu errado.',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Ocorreu um erro inesperado na interface.\nNossa equipe já foi notificada.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s32),
              ElevatedButton(
                onPressed: () {
                  // In a real app, strict navigation reset might be needed
                  // But usually we just hope a hot restart or navigating back works
                  // For now, we don't have a reliable "retry" mechanism for the whole tree
                  // without causing loops.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  @override
  void initState() {
    super.initState();
    // No-op: ErrorBoundary in Flutter typically relies on catching errors
    // in the build phase or using ErrorWidget.builder.
    // However, for a true "catch-all" within a subtree, we often use
    // a customized builder or error handling zone.
    // But since Flutter 3.10+, ErrorWidget.builder is global.
    //
    // For a local boundary, we can't easily "catch" render exceptions
    // from children unless we are the ones building them in a protected way.
    //
    // A common pattern in Flutter is simply using ErrorWidget.builder globally.
    // BUT, we can simulate a boundary by checking if we have valid data/state
    // in the parent.
    //
    // Since true Error Boundaries like React don't usually exist in Flutter
    // for separate subtrees (exceptions bubble up to the global handler),
    // this widget defines a customized error display that we can use
    // globally via ErrorWidget.builder.
  }

  @override
  Widget build(BuildContext context) {
    // In Flutter, we normally set ErrorWidget.builder globally in main.dart
    // This widget is a placeholder if we wanted to use runZonedGuarded logic
    // specific to a subtree, but strictly speaking, Widget build errors
    // go to ErrorWidget.builder.
    return widget.child;
  }
}
