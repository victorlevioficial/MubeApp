import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/design_system/components/components.dart';
import 'package:mube/src/design_system/foundations/tokens/app_colors.dart';
import 'package:mube/src/design_system/foundations/tokens/app_radius.dart';
import 'package:mube/src/design_system/foundations/tokens/app_spacing.dart';
import 'package:mube/src/design_system/foundations/tokens/app_typography.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/routing/route_paths.dart';

class MatchpointMatchesScreen extends ConsumerWidget {
  const MatchpointMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemCount: matches.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.s12),
            itemBuilder: (context, index) {
              final match = matches[index];
              final otherUser = match.otherUser;
              
              return FadeInSlide(
                duration: const Duration(milliseconds: 400),
                child: _MatchTile(
                  userName: otherUser?.nome ?? 'Usuário',
                  userPhoto: otherUser?.foto,
                  userId: match.otherUserId,
                  conversationId: match.conversationId,
                  onTap: () {
                    if (match.conversationId != null) {
                      context.push(
                        '${RoutePaths.conversation}/${match.conversationId}',
                        extra: {
                          'otherUserId': match.otherUserId,
                          'otherUserName': otherUser?.nome ?? 'Usuário',
                          'otherUserPhoto': otherUser?.foto,
                        },
                      );
                    }
                  },
                  onUnmatch: () => _confirmUnmatch(
                    context,
                    ref,
                    match.otherUserId,
                    otherUser?.nome ?? 'Usuário',
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
            onPressed: () => ref.refresh(matchesProvider),
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
        text: 'Explorar',
        onPressed: () {
          // Voltar para a aba de explorar
          // Isso será tratado pelo IndexedStack no parent
        },
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String userName;
  final String? userPhoto;
  final String userId;
  final String? conversationId;
  final VoidCallback onTap;
  final VoidCallback onUnmatch;

  const _MatchTile({
    required this.userName,
    required this.userPhoto,
    required this.userId,
    this.conversationId,
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
                photoUrl: userPhoto,
                name: userName,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Novo Match! Diga Olá 👋',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppTypography.buttonPrimary.fontWeight,
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
                              '${RoutePaths.publicProfile}/$userId',
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
