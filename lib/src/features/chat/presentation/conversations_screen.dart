import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/mube_app_bar.dart';
import '../../../common_widgets/user_avatar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../data/chat_providers.dart';
import '../domain/conversation_preview.dart';

/// Tela com lista de conversas do usuário.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(userConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MubeAppBar(title: 'Conversas'),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: AppSpacing.v8,
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final preview = conversations[index];
              return _ConversationTile(
                preview: preview,
                onTap: () =>
                    context.push('${RoutePaths.conversation}/${preview.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Erro ao carregar conversas',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Nenhuma conversa ainda',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s48),
            child: Text(
              'Inicie uma conversa visitando o perfil de outro usuário',
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

class _ConversationTile extends StatelessWidget {
  final ConversationPreview preview;
  final VoidCallback onTap;

  const _ConversationTile({required this.preview, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface, // Same as FeedCardVertical
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(
            alpha: 0.5,
          ), // Same as FeedCardVertical
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              UserAvatar(
                size: 56,
                photoUrl: preview.otherUserPhoto,
                name: preview.otherUserName,
              ),
              const SizedBox(width: AppSpacing.s12),

              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nome
                        Expanded(
                          child: Text(
                            preview.otherUserName,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 16,
                              fontWeight: preview.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Hora
                        if (preview.lastMessageAt != null)
                          Text(
                            _formatTime(preview.lastMessageAt!.toDate()),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Última mensagem
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview.lastMessageText ?? 'Nova conversa',
                            style: AppTypography.bodyMedium.copyWith(
                              color: preview.unreadCount > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: preview.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Badge de não lidas (Solid Neon Dot)
                        if (preview.unreadCount > 0) ...[
                          const SizedBox(width: AppSpacing.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary, // Solid Neon Color
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${preview.unreadCount}',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
