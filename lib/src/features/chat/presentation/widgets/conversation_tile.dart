import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/conversation_preview.dart';

/// Widget de tile para item da lista de conversas
class ConversationTile extends ConsumerWidget {
  final ConversationPreview conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEE').format(date);
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Buscar perfil real do outro usuário
    final profileAsync = ref.watch(
      userProfileProvider(conversation.otherUserId),
    );

    final displayName = profileAsync.when(
      data: (profile) {
        if (profile == null) return conversation.otherUserName;
        // Usar nome artístico se disponível
        final artisticName =
            profile.dadosProfissional?['nomeArtistico'] as String? ??
            profile.dadosBanda?['nome'] as String? ??
            profile.dadosEstudio?['nome'] as String? ??
            profile.dadosContratante?['nome'] as String?;
        return artisticName ?? profile.nome ?? conversation.otherUserName;
      },
      loading: () => conversation.otherUserName,
      error: (_, __) => conversation.otherUserName,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceHighlight, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.surfaceHighlight,
              backgroundImage: conversation.otherUserPhoto != null
                  ? CachedNetworkImageProvider(conversation.otherUserPhoto!)
                  : null,
              child: conversation.otherUserPhoto == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: AppSpacing.s12),

            // Nome, última mensagem
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    displayName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Última mensagem
                  if (conversation.lastMessage.isNotEmpty)
                    Text(
                      conversation.lastMessage,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.s8),

            // Hora e badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Hora
                Text(
                  _formatTime(conversation.lastMessageTime),
                  style: AppTypography.bodySmall.copyWith(
                    color: conversation.unreadCount > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 4),

                // Badge de não lidas (apenas se > 0)
                if (conversation.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : conversation.unreadCount.toString(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
