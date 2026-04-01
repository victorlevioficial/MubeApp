import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/story_viewer_route_args.dart';
import '../controllers/story_viewer_controller.dart';
import 'story_viewer_screen.dart';

class StoryViewerRouteLoader extends ConsumerWidget {
  const StoryViewerRouteLoader({
    super.key,
    required this.storyId,
    this.preloadedArgs,
  });

  final String storyId;
  final StoryViewerRouteArgs? preloadedArgs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = preloadedArgs;
    if (args != null) {
      return StoryViewerScreen(args: args);
    }

    final routeArgsAsync = ref.watch(storyViewerRouteArgsProvider(storyId));

    return routeArgsAsync.when(
      data: (resolvedArgs) => StoryViewerScreen(args: resolvedArgs),
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stackTrace) {
        final message = error.toString();
        if (message.contains('Story nao encontrado.')) {
          return const _StoryViewerFallbackState(
            title: 'Story nao encontrado.',
            subtitle: 'Esse story nao esta mais disponivel.',
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Padding(
              padding: AppSpacing.all24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nao foi possivel carregar o story.',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Tente novamente em alguns instantes.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  AppButton.primary(
                    text: 'Tentar novamente',
                    onPressed: () =>
                        ref.invalidate(storyViewerRouteArgsProvider(storyId)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoryViewerFallbackState extends StatelessWidget {
  const _StoryViewerFallbackState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: AppSpacing.all24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
