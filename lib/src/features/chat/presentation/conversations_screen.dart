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

class _ConversationsScreenState extends ConsumerState<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _deletingConversationIds = <String>{};
  final Set<String> _hiddenConversationIds = <String>{};
  final Set<String> _acceptingConversationIds = <String>{};
  final Set<String> _rejectingConversationIds = <String>{};
  final Map<String, ConversationPreview> _optimisticallyAcceptedConversations =
      <String, ConversationPreview>{};
  final Map<String, int?> _hiddenPendingConversationCycles = <String, int?>{};

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _invalidateConversationStreams() {
    ref.invalidate(userConversationsProvider);
    ref.invalidate(userAcceptedConversationsProvider);
    ref.invalidate(userPendingConversationsProvider);
  }

  ConversationPreview _buildAcceptedPreview(ConversationPreview preview) {
    return ConversationPreview(
      id: preview.id,
      otherUserId: preview.otherUserId,
      otherUserName: preview.otherUserName,
      otherUserPhoto: preview.otherUserPhoto,
      lastMessageText: preview.lastMessageText,
      lastMessageAt: preview.lastMessageAt,
      lastSenderId: preview.lastSenderId,
      unreadCount: preview.unreadCount,
      updatedAt: preview.updatedAt,
      type: preview.type,
      isPending: false,
      requestCycle: null,
    );
  }

  int _compareConversationOrder(ConversationPreview a, ConversationPreview b) {
    final aTimestamp = a.lastMessageAt ?? a.updatedAt;
    final bTimestamp = b.lastMessageAt ?? b.updatedAt;
    return bTimestamp.compareTo(aTimestamp);
  }

  List<ConversationPreview> _mergeAcceptedConversations(
    List<ConversationPreview> conversations,
  ) {
    final byId = <String, ConversationPreview>{
      for (final preview in _optimisticallyAcceptedConversations.values)
        preview.id: preview,
      for (final preview in conversations) preview.id: preview,
    };

    final merged = byId.values.toList(growable: false);
    merged.sort(_compareConversationOrder);
    return merged;
  }

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

    if (deleted) {
      _invalidateConversationStreams();
    }

    return deleted;
  }

  Future<bool> _acceptConversationRequest(ConversationPreview preview) async {
    if (_acceptingConversationIds.contains(preview.id) ||
        _rejectingConversationIds.contains(preview.id)) {
      return false;
    }

    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) {
      AppSnackBar.error(context, 'Usuario nao autenticado.');
      return false;
    }

    setState(() {
      _acceptingConversationIds.add(preview.id);
    });

    final repository = ref.read(chatRepositoryProvider);
    final result = await repository.acceptConversationRequest(
      conversationId: preview.id,
      myUid: currentUser.uid,
      otherUid: preview.otherUserId,
    );

    if (!mounted) return false;

    var accepted = false;
    result.fold(
      (failure) => AppSnackBar.error(
        context,
        'Erro ao aceitar solicitacao: ${failure.message}',
      ),
      (_) {
        accepted = true;
        AppSnackBar.success(context, 'Solicitacao aceita.');
      },
    );

    setState(() {
      _acceptingConversationIds.remove(preview.id);
      if (accepted) {
        _optimisticallyAcceptedConversations[preview.id] =
            _buildAcceptedPreview(preview);
        _hiddenPendingConversationCycles.remove(preview.id);
      }
    });

    if (accepted) {
      _tabController.animateTo(0);
      _invalidateConversationStreams();
    }

    return accepted;
  }

  Future<bool> _rejectConversationRequest(ConversationPreview preview) async {
    if (_acceptingConversationIds.contains(preview.id) ||
        _rejectingConversationIds.contains(preview.id)) {
      return false;
    }

    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) {
      AppSnackBar.error(context, 'Usuario nao autenticado.');
      return false;
    }

    final confirmed = await AppOverlay.dialog<bool>(
      context: context,
      builder: (dialogContext) => const AppConfirmationDialog(
        title: 'Recusar solicitacao?',
        message:
            'A conversa saira de Solicitacoes, mas podera reaparecer se a pessoa enviar uma nova mensagem.',
        confirmText: 'Recusar',
        isDestructive: true,
      ),
    );

    if (confirmed != true || !mounted) return false;

    setState(() {
      _rejectingConversationIds.add(preview.id);
    });

    final repository = ref.read(chatRepositoryProvider);
    final result = await repository.rejectConversationRequest(
      conversationId: preview.id,
      myUid: currentUser.uid,
      otherUid: preview.otherUserId,
    );

    if (!mounted) return false;

    var rejected = false;
    result.fold(
      (failure) => AppSnackBar.error(
        context,
        'Erro ao recusar solicitacao: ${failure.message}',
      ),
      (_) {
        rejected = true;
        AppSnackBar.success(context, 'Solicitacao recusada.');
      },
    );

    setState(() {
      _rejectingConversationIds.remove(preview.id);
      if (rejected) {
        _hiddenPendingConversationCycles[preview.id] = preview.requestCycle;
      }
    });

    if (rejected) {
      _invalidateConversationStreams();
    }

    return rejected;
  }

  Future<void> _refreshConversations() async {
    try {
      await Future.wait([
        ref.refresh(userConversationsProvider.future),
        ref.refresh(userAcceptedConversationsProvider.future),
        ref.refresh(userPendingConversationsProvider.future),
      ]);
    } catch (_) {
      // Keep pull-to-refresh silent when stream emits error.
    }
  }

  bool _hasConversationActivity(ConversationPreview preview) {
    final lastMessageText = preview.lastMessageText?.trim();
    return preview.lastMessageAt != null ||
        (lastMessageText != null && lastMessageText.isNotEmpty);
  }

  bool _isHiddenPendingConversation(ConversationPreview preview) {
    return _hiddenPendingConversationCycles[preview.id] == preview.requestCycle;
  }

  Future<bool> _handlePendingDismiss(
    ConversationPreview preview,
    DismissDirection direction,
  ) {
    if (direction == DismissDirection.startToEnd) {
      return _acceptConversationRequest(preview);
    }
    if (direction == DismissDirection.endToStart) {
      return _rejectConversationRequest(preview);
    }
    return Future.value(false);
  }

  void _openConversation(BuildContext context, ConversationPreview preview) {
    context.push(
      RoutePaths.conversationById(preview.id),
      extra: {
        'otherUserId': preview.otherUserId,
        'otherUserName': preview.otherUserName,
        'otherUserPhoto': preview.otherUserPhoto,
        'conversationType': preview.type,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final acceptedAsync = ref.watch(userAcceptedConversationsProvider);
    final pendingAsync = ref.watch(userPendingConversationsProvider);
    final currentUserId = ref.watch(currentUserIdProvider) ?? '';
    final pendingCount =
        pendingAsync.value
            ?.where(
              (preview) =>
                  preview.type != 'matchpoint' &&
                  !_optimisticallyAcceptedConversations.containsKey(
                    preview.id,
                  ) &&
                  !_isHiddenPendingConversation(preview) &&
                  _hasConversationActivity(preview),
            )
            .length ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Conversas',
        bottom: TabBar(
          controller: _tabController,
          dividerColor: AppColors.surfaceHighlight.withValues(alpha: 0.6),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.titleSmall.copyWith(
            fontWeight: AppTypography.buttonPrimary.fontWeight,
          ),
          unselectedLabelStyle: AppTypography.titleSmall,
          tabs: [
            const Tab(text: 'Conversas'),
            Tab(
              child: _TabLabel(text: 'Solicitacoes', count: pendingCount),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAcceptedTab(
            context: context,
            conversationsAsync: acceptedAsync,
            currentUserId: currentUserId,
          ),
          _buildPendingTab(
            context: context,
            conversationsAsync: pendingAsync,
            currentUserId: currentUserId,
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedTab({
    required BuildContext context,
    required AsyncValue<List<ConversationPreview>> conversationsAsync,
    required String currentUserId,
  }) {
    return conversationsAsync.when(
      data: (conversations) {
        final visibleConversations = _mergeAcceptedConversations(conversations)
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
                  child: _buildEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Nenhuma conversa ainda',
                    message: 'Suas conexoes e amigos aparecerao aqui.',
                  ),
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
              final isDeleting = _deletingConversationIds.contains(preview.id);
              return Dismissible(
                key: ValueKey('accepted_${preview.id}'),
                direction: isDeleting
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDeleteConversation(preview),
                background: const _ConversationSwipeBackground(
                  color: AppColors.error,
                  icon: Icons.visibility_off_outlined,
                  label: 'Ocultar',
                  alignment: Alignment.centerRight,
                ),
                child: _ConversationTile(
                  key: ValueKey(preview.id),
                  preview: preview,
                  currentUserId: currentUserId,
                  isProcessing: isDeleting,
                  semanticHint:
                      'Toque para abrir. Deslize para ocultar conversa.',
                  onTap: () => _openConversation(context, preview),
                ),
              );
            },
          ),
        );
      },
      loading: () =>
          const SkeletonShimmer(child: UserListSkeleton(itemCount: 5)),
      error: (error, stack) => _buildErrorState(
        context: context,
        title: 'Erro ao carregar conversas',
      ),
    );
  }

  Widget _buildPendingTab({
    required BuildContext context,
    required AsyncValue<List<ConversationPreview>> conversationsAsync,
    required String currentUserId,
  }) {
    return conversationsAsync.when(
      data: (conversations) {
        final visibleConversations = conversations
            .where(
              (conversation) =>
                  conversation.type != 'matchpoint' &&
                  !_optimisticallyAcceptedConversations.containsKey(
                    conversation.id,
                  ) &&
                  _hasConversationActivity(conversation) &&
                  !_isHiddenPendingConversation(conversation),
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
                  child: _buildEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Nenhuma solicitacao',
                    message:
                        'Novas mensagens recebidas em chat privado aparecerao aqui.',
                  ),
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
              final isProcessing =
                  _acceptingConversationIds.contains(preview.id) ||
                  _rejectingConversationIds.contains(preview.id);
              return Dismissible(
                key: ValueKey('pending_${preview.id}_${preview.requestCycle}'),
                direction: isProcessing
                    ? DismissDirection.none
                    : DismissDirection.horizontal,
                confirmDismiss: (direction) =>
                    _handlePendingDismiss(preview, direction),
                background: const _ConversationSwipeBackground(
                  color: AppColors.primary,
                  icon: Icons.check_rounded,
                  label: 'Aceitar',
                  alignment: Alignment.centerLeft,
                ),
                secondaryBackground: const _ConversationSwipeBackground(
                  color: AppColors.error,
                  icon: Icons.close_rounded,
                  label: 'Recusar',
                  alignment: Alignment.centerRight,
                ),
                child: _ConversationTile(
                  key: ValueKey('${preview.id}_${preview.requestCycle}'),
                  preview: preview,
                  currentUserId: currentUserId,
                  isProcessing: isProcessing,
                  semanticHint:
                      'Toque para abrir. Deslize para aceitar ou recusar solicitacao.',
                  onTap: () => _openConversation(context, preview),
                ),
              );
            },
          ),
        );
      },
      loading: () =>
          const SkeletonShimmer(child: UserListSkeleton(itemCount: 4)),
      error: (error, stack) => _buildErrorState(
        context: context,
        title: 'Erro ao carregar solicitacoes',
      ),
    );
  }

  Widget _buildErrorState({
    required BuildContext context,
    required String title,
  }) {
    return AppRefreshIndicator(
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
                    title,
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
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            title,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s48),
            child: Text(
              message,
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

class _TabLabel extends StatelessWidget {
  final String text;
  final int count;

  const _TabLabel({required this.text, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (count > 0) ...[
          const SizedBox(width: AppSpacing.s8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s8,
              vertical: AppSpacing.s2,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.all12,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textPrimary,
                fontWeight: AppTypography.buttonPrimary.fontWeight,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationPreview preview;
  final String currentUserId;
  final VoidCallback onTap;
  final bool isProcessing;
  final String semanticHint;

  const _ConversationTile({
    super.key,
    required this.preview,
    required this.currentUserId,
    required this.onTap,
    required this.semanticHint,
    this.isProcessing = false,
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
      opacity: isProcessing ? 0.6 : 1,
      child: Semantics(
        button: true,
        label:
            'Conversa com ${preview.otherUserName}$semanticUnread$semanticTime. Ultima mensagem: $lastMessagePreview',
        hint: semanticHint,
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
            onTap: isProcessing ? null : onTap,
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
                            if (isProcessing) ...[
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

class _ConversationSwipeBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  const _ConversationSwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final isStartAligned = alignment == Alignment.centerLeft;

    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.all16),
      child: Row(
        mainAxisAlignment: isStartAligned
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (!isStartAligned) ...[
            Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.95)),
            const SizedBox(width: AppSpacing.s8),
          ],
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.titleSmall.fontWeight,
            ),
          ),
          if (isStartAligned) ...[
            const SizedBox(width: AppSpacing.s8),
            Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.95)),
          ],
        ],
      ),
    );
  }
}
