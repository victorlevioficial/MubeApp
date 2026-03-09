import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/data_display/user_avatar.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_refresh_indicator.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_skeleton.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';
import '../domain/conversation_preview.dart';

/// Tela com lista de conversas do usuario.
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final Set<String> _deletingConversationIds = <String>{};
  final Set<String> _hiddenConversationIds = <String>{};

  Future<bool> _confirmDeleteConversation(ConversationPreview preview) async {
    if (_deletingConversationIds.contains(preview.id)) return false;

    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) {
      AppSnackBar.error(context, 'Usuario nao autenticado.');
      return false;
    }

    final confirmed = await AppOverlay.dialog<bool>(
      context: context,
      builder: (dialogContext) => const AppConfirmationDialog(
        title: 'Ocultar conversa?',
        message:
            'Essa conversa sera removida apenas da sua lista. O historico continuara salvo.',
        confirmText: 'Ocultar',
      ),
    );

    if (confirmed != true || !mounted) return false;

    setState(() {
      _deletingConversationIds.add(preview.id);
    });

    final repository = ref.read(chatRepositoryProvider);
    final result = await repository.deleteConversation(
      conversationId: preview.id,
      myUid: currentUser.uid,
      otherUid: preview.otherUserId,
    );

    if (!mounted) return false;

    var deleted = false;
    result.fold(
      (failure) => AppSnackBar.error(
        context,
        'Erro ao ocultar conversa: ${failure.message}',
      ),
      (_) {
        deleted = true;
        AppSnackBar.success(context, 'Conversa removida da sua lista.');
      },
    );

    setState(() {
      _deletingConversationIds.remove(preview.id);
      if (deleted) {
        _hiddenConversationIds.add(preview.id);
      }
    });

    return deleted;
  }

  Future<void> _refreshConversations() async {
    try {
      final refreshFuture = ref.refresh(userConversationsProvider.future);
      await refreshFuture;
    } catch (_) {
      // Keep pull-to-refresh silent when stream emits error.
    }
  }

  bool _hasConversationActivity(ConversationPreview preview) {
    final lastMessageText = preview.lastMessageText?.trim();
    return preview.lastMessageAt != null ||
        (lastMessageText != null && lastMessageText.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(directConversationsProvider);
    final currentUserId =
        ref.watch(currentUserProfileProvider).value?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Conversas'),
      body: conversationsAsync.when(
        data: (conversations) {
          final visibleConversations = conversations
              .where(
                (conversation) =>
                    _hasConversationActivity(conversation) &&
                    !_hiddenConversationIds.contains(conversation.id),
              )
              .toList(growable: false);
          if (visibleConversations.isEmpty) {
            return AppRefreshIndicator(
              onRefresh: _refreshConversations,
              child: ListView(
                physics: AppRefreshIndicator.defaultScrollPhysics,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.72,
                    child: _buildEmptyState(),
                  ),
                ],
              ),
            );
          }
          return AppRefreshIndicator(
            onRefresh: _refreshConversations,
            child: ListView.builder(
              physics: AppRefreshIndicator.defaultScrollPhysics,
              padding: AppSpacing.v8,
              itemCount: visibleConversations.length,
              itemBuilder: (context, index) {
                final preview = visibleConversations[index];
                final isDeleting = _deletingConversationIds.contains(
                  preview.id,
                );
                return Dismissible(
                  key: ValueKey('dismiss_${preview.id}'),
                  direction: isDeleting
                      ? DismissDirection.none
                      : DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDeleteConversation(preview),
                  background: const _ConversationDismissBackground(),
                  child: _ConversationTile(
                    key: ValueKey(preview.id),
                    preview: preview,
                    currentUserId: currentUserId,
                    isDeleting: isDeleting,
                    onTap: () => context.push(
                      RoutePaths.conversationById(preview.id),
                      extra: {
                        'otherUserId': preview.otherUserId,
                        'otherUserName': preview.otherUserName,
                        'otherUserPhoto': preview.otherUserPhoto,
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () =>
            const SkeletonShimmer(child: UserListSkeleton(itemCount: 5)),
        error: (error, stack) => AppRefreshIndicator(
          onRefresh: _refreshConversations,
          child: ListView(
            physics: AppRefreshIndicator.defaultScrollPhysics,
            padding: AppSpacing.all24,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        size: 42,
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        'Erro ao carregar conversas',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'Puxe para atualizar ou tente novamente.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      OutlinedButton.icon(
                        onPressed: _refreshConversations,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
              'Suas conexoes e amigos aparecerao aqui.',
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
  final String currentUserId;
  final VoidCallback onTap;
  final bool isDeleting;

  const _ConversationTile({
    super.key,
    required this.preview,
    required this.currentUserId,
    required this.onTap,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessagePreview = _lastMessagePreviewText();
    final semanticTime = preview.lastMessageAt == null
        ? ''
        : ', ${_formatTime(preview.lastMessageAt!.toDate().toLocal())}';
    final semanticUnread = preview.unreadCount > 0
        ? ', ${preview.unreadCount} nao lidas'
        : ', sem mensagens nao lidas';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isDeleting ? 0.6 : 1,
      child: Semantics(
        button: true,
        label:
            'Conversa com ${preview.otherUserName}$semanticUnread$semanticTime. Ultima mensagem: $lastMessagePreview',
        hint: 'Toque para abrir. Deslize para ocultar conversa.',
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: isDeleting ? null : onTap,
            borderRadius: AppRadius.all16,
            child: Padding(
              padding: AppSpacing.all16,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                preview.otherUserName,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: preview.unreadCount > 0
                                      ? AppTypography.buttonPrimary.fontWeight
                                      : AppTypography.titleSmall.fontWeight,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (preview.lastMessageAt != null)
                              Text(
                                _formatTime(
                                  preview.lastMessageAt!.toDate().toLocal(),
                                ),
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessagePreview,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: preview.unreadCount > 0
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: preview.unreadCount > 0
                                      ? AppTypography.titleSmall.fontWeight
                                      : AppTypography.bodyMedium.fontWeight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDeleting) ...[
                              const SizedBox(width: AppSpacing.s8),
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ] else if (preview.unreadCount > 0) ...[
                              const SizedBox(width: AppSpacing.s8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s8,
                                  vertical: AppSpacing.s4,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: AppRadius.all12,
                                ),
                                child: Text(
                                  '${preview.unreadCount}',
                                  style: AppTypography.chipLabel.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight:
                                        AppTypography.buttonPrimary.fontWeight,
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
        ),
      ),
    );
  }

  String _lastMessagePreviewText() {
    final message = preview.lastMessageText?.trim();
    if (message == null || message.isEmpty) return 'Nova conversa';
    if (preview.lastSenderId != null && preview.lastSenderId == currentUserId) {
      return 'Voce: $message';
    }
    return message;
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

class _ConversationDismissBackground extends StatelessWidget {
  const _ConversationDismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      decoration: const BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.all16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.visibility_off_outlined,
            color: AppColors.textPrimary.withValues(alpha: 0.95),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            'Ocultar',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.titleSmall.fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}
