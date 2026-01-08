import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../domain/message.dart';

/// Widget de balão de mensagem individual
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isRead;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isRead,
  });

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64 : AppSpacing.s16,
          right: isMe ? AppSpacing.s16 : 64,
          bottom: AppSpacing.s8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Texto da mensagem
            Text(
              message.text,
              style: AppTypography.bodyMedium.copyWith(
                color: isMe ? AppColors.textPrimary : AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            // Hora e status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: AppTypography.bodySmall.copyWith(
                    color: isMe
                        ? AppColors.textSecondary
                        : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),

                // Status apenas para minhas mensagens
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: isRead
                        ? AppColors
                              .primary // ✓✓ (lida)
                        : AppColors.textSecondary, // ✓ (enviada)
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
