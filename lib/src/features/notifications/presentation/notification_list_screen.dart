import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../data/notification_providers.dart';
import '../domain/notification_model.dart';

/// Screen to display all notifications from Firestore.
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final user = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Notificações',
        actions: [
          if (notificationsAsync.value?.isNotEmpty == true)
            TextButton(
              onPressed: () => _clearAllNotifications(context, ref, user?.uid),
              child: Text(
                'Limpar',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Erro ao carregar notificações',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.s16),
                  color: AppColors.error,
                  child: const Icon(
                    Icons.delete,
                    color: AppColors.textPrimary,
                  ),
                ),
                onDismissed: (_) {
                  if (user != null) {
                    ref
                        .read(notificationRepositoryProvider)
                        .deleteNotification(user.uid, notification.id);
                  }
                },
                child: _NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(
                    context,
                    ref,
                    notification,
                    user?.uid,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
    String? userId,
  ) {
    // Mark as read
    if (userId != null && !notification.isRead) {
      ref
          .read(notificationRepositoryProvider)
          .markAsRead(userId, notification.id);
    }

    // Navigate based on type
    switch (notification.type) {
      case NotificationType.chatMessage:
        if (notification.conversationId != null) {
          context.push('/conversation/${notification.conversationId}');
        }
        break;
      case NotificationType.bandInvite:
        context.push('/invites');
        break;
      case NotificationType.like:
      case NotificationType.system:
        // No specific navigation for now
        break;
    }
  }

  void _clearAllNotifications(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) {
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Limpar notificações',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Deseja apagar todas as notificações?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(notificationRepositoryProvider)
                  .deleteAllNotifications(userId);
            },
            child: Text(
              'Limpar',
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
          const Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Nenhuma notificação',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Você será notificado quando houver novidades',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const _NotificationTile({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
        border: !notification.isRead
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: AppRadius.all12,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: AppRadius.all12,
                  ),
                  child: Icon(
                    _getIconForType(notification.type),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: !notification.isRead
                              ? AppTypography.buttonPrimary.fontWeight
                              : AppTypography.bodyLarge.fontWeight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        notification.body,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                // Time + unread indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(notification.createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Container(
                        width: AppSpacing.s8,
                        height: AppSpacing.s8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.chatMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.bandInvite:
        return Icons.group_add_outlined;
      case NotificationType.like:
        return Icons.favorite_border;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return DateFormat('dd/MM').format(createdAt);
  }
}
