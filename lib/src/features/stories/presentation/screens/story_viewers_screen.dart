import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../controllers/story_viewer_controller.dart';

class StoryViewersScreen extends ConsumerWidget {
  const StoryViewersScreen({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewersAsync = ref.watch(storyViewersProvider(storyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Visualizacoes'),
      ),
      body: viewersAsync.when(
        data: (viewers) {
          if (viewers.isEmpty) {
            return Center(
              child: Text(
                'Ninguem visualizou este story ainda.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: viewers.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
            itemBuilder: (context, index) {
              final viewer = viewers[index];
              return Row(
                children: [
                  UserAvatar(
                    photoUrl: viewer.viewerPhoto,
                    name: viewer.viewerName,
                    size: 52,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viewer.viewerName,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          DateFormat(
                            'dd/MM - HH:mm',
                          ).format(viewer.viewedAt.toLocal()),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Nao foi possivel carregar as visualizacoes.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
