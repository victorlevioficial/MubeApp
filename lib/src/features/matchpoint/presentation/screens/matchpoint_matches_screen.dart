import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/common_widgets/app_skeleton.dart';
import 'package:mube/src/common_widgets/user_avatar.dart';
import 'package:mube/src/design_system/foundations/app_colors.dart';
import 'package:mube/src/design_system/foundations/app_spacing.dart';
import 'package:mube/src/design_system/foundations/app_typography.dart';
import 'package:mube/src/features/chat/data/chat_providers.dart';
import 'package:mube/src/features/chat/domain/conversation_preview.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/routing/route_paths.dart';

class MatchpointMatchesScreen extends ConsumerWidget {
  const MatchpointMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(matchConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemCount: conversations.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.s12),
            itemBuilder: (context, index) {
              final preview = conversations[index];
              return _MatchTile(
                preview: preview,
                onTap: () => context.push(
                  '${RoutePaths.conversation}/${preview.id}',
                  extra: {
                    'otherUserId': preview.otherUserId,
                    'otherUserName': preview.otherUserName,
                    'otherUserPhoto': preview.otherUserPhoto,
                  },
                ),
                onUnmatch: () => _confirmUnmatch(
                  context,
                  ref,
                  preview.otherUserId,
                  preview.otherUserName,
                ),
              );
            },
          );
        },
        loading: () =>
            const SkeletonShimmer(child: UserListSkeleton(itemCount: 5)),
        error: (error, stack) => Center(
          child: Text(
            'Erro ao carregar matches',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmUnmatch(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Desfazer Match com $name?',
          style: AppTypography.titleLarge,
        ),
        content: Text(
          'A conversa será apagada e vocês não aparecerão mais um para o outro.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(matchpointControllerProvider.notifier)
                  .unmatchUser(targetUserId);
              context.pop();
            },
            child: Text(
              'Desfazer Match',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Nenhum match ainda',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
            child: Text(
              'Curta perfis para conectar com outros músicos!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final ConversationPreview preview;
  final VoidCallback onTap;
  final VoidCallback onUnmatch;

  const _MatchTile({
    required this.preview,
    required this.onTap,
    required this.onUnmatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(
                size: 56,
                photoUrl: preview.otherUserPhoto,
                name: preview.otherUserName,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.otherUserName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.lastMessageText ?? 'Novo Match! Diga Olá 👋',
                      style: AppTypography.bodySmall.copyWith(
                        color: preview.unreadCount > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: preview.unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textTertiary,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.surface,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: AppColors.textPrimary,
                          ),
                          title: const Text(
                            'Ver Perfil',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          onTap: () {
                            context.pop();
                            context.push(
                              '${RoutePaths.publicProfile}/${preview.otherUserId}',
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.heart_broken,
                            color: AppColors.error,
                          ),
                          title: const Text(
                            'Desfazer Match',
                            style: TextStyle(color: AppColors.error),
                          ),
                          onTap: () {
                            context.pop();
                            onUnmatch();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
