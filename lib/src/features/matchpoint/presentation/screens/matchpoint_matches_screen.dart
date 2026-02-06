import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/design_system/components/components.dart';
import 'package:mube/src/design_system/foundations/tokens/app_colors.dart';
import 'package:mube/src/design_system/foundations/tokens/app_radius.dart';
import 'package:mube/src/design_system/foundations/tokens/app_spacing.dart';
import 'package:mube/src/design_system/foundations/tokens/app_typography.dart';
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
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemCount: conversations.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.s12),
            itemBuilder: (context, index) {
              final preview = conversations[index];
              return FadeInSlide(
                duration: const Duration(milliseconds: 400),
                child: _MatchTile(
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
                ),
              );
            },
          );
        },
        loading: () =>
            const SkeletonShimmer(child: UserListSkeleton(itemCount: 5)),
        error: (error, stack) => EmptyStateWidget(
          title: 'Erro ao carregar',
          subtitle: 'Não foi possível carregar seus matches.',
          icon: Icons.error_outline,
          actionButton: AppButton.secondary(
            text: 'Tentar novamente',
            onPressed: () => ref.refresh(matchConversationsProvider),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmUnmatch(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: 'Desfazer Match com $name?',
        message:
            'A conversa será apagada e vocês não aparecerão mais um para o outro.',
        confirmText: 'Desfazer Match',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      await ref
          .read(matchpointControllerProvider.notifier)
          .unmatchUser(targetUserId);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      title: 'Nenhum match ainda',
      subtitle: 'Curta perfis para conectar com outros músicos!',
      icon: Icons.favorite_border,
      actionButton: AppButton.primary(
        text: 'Ir para o Feed',
        onPressed: () => context.go(RoutePaths.feed),
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
    return AppAnimatedPress(
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.all16,
          border: Border.all(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: AppSpacing.all12,
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
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      preview.lastMessageText ?? 'Novo Match! Diga Olá 👋',
                      style: AppTypography.bodySmall.copyWith(
                        color: preview.unreadCount > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: preview.unreadCount > 0
                            ? AppTypography.buttonPrimary.fontWeight
                            : AppTypography.bodySmall.fontWeight,
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
                          title: Text(
                            'Ver Perfil',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
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
                          title: Text(
                            'Desfazer Match',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          onTap: () {
                            context.pop();
                            onUnmatch();
                          },
                        ),
                        const SizedBox(height: AppSpacing.s16),
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
