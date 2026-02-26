import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../design_system/components/data_display/user_avatar.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/loading/app_shimmer.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';
import '../domain/conversation_preview.dart';
import '../domain/message.dart';

/// Tela de chat 1:1.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final Map<String, dynamic>? extra;

  const ChatScreen({super.key, required this.conversationId, this.extra});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

enum _ConversationAccessState { checking, ready, unavailable, forbidden }

class _PendingMessage {
  final String localId;
  final String text;
  final DateTime createdAt;

  const _PendingMessage({
    required this.localId,
    required this.text,
    required this.createdAt,
  });
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_PendingMessage> _pendingMessages = [];
  ProviderSubscription<AsyncValue<List<Message>>>?
  _messagesReadReceiptSubscription;
  bool _isNavigatingToEmailVerification = false;
  _ConversationAccessState _accessState = _ConversationAccessState.checking;
  String? _conversationAccessMessage;
  bool? _cachedEmailSendAllowed;
  DateTime? _cachedEmailCheckAt;

  // Dados do outro usuario (pode vir via extra ou cache local)
  late String _otherUserName;
  String? _otherUserPhoto;
  late String _otherUserId;

  bool get _canReadConversation =>
      _accessState == _ConversationAccessState.ready;

  static const Duration _verifiedEmailCacheTtl = Duration(minutes: 5);
  static const Duration _unverifiedEmailCacheTtl = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    PushNotificationService.setActiveConversation(widget.conversationId);

    _initializeData();
    unawaited(_prepareConversation());
  }

  void _initializeData() {
    final extra = widget.extra;

    final cachedPreview = ref
        .read(userConversationsProvider)
        .value
        ?.firstWhere(
          (p) => p.id == widget.conversationId,
          orElse: () => ConversationPreview(
            id: widget.conversationId,
            otherUserId: '',
            otherUserName: 'Usuario',
            unreadCount: 0,
            updatedAt: Timestamp.now(),
          ),
        );

    _otherUserName =
        extra?['otherUserName'] ?? cachedPreview?.otherUserName ?? 'Usuario';
    _otherUserPhoto = extra?['otherUserPhoto'] ?? cachedPreview?.otherUserPhoto;
    _otherUserId = extra?['otherUserId'] ?? cachedPreview?.otherUserId ?? '';
  }

  Future<void> _prepareConversation() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      if (mounted) {
        setState(() {
          _accessState = _ConversationAccessState.unavailable;
          _conversationAccessMessage = 'Usuario nao autenticado.';
        });
      }
      return;
    }

    final repository = ref.read(chatRepositoryProvider);

    try {
      final existingDoc = await repository.getConversationDoc(
        widget.conversationId,
      );
      if (!mounted) return;

      if (existingDoc != null && existingDoc.exists) {
        if (!_isUserParticipant(existingDoc, user.uid)) {
          setState(() {
            _accessState = _ConversationAccessState.forbidden;
            _conversationAccessMessage =
                'Voce nao tem permissao para acessar esta conversa.';
          });
          return;
        }

        setState(() {
          _accessState = _ConversationAccessState.ready;
          _conversationAccessMessage = null;
        });
        unawaited(_markConversationAsRead(repository, user.uid));
        _startRealtimeReadReceiptListener(user.uid, repository);
        return;
      }

      if (_otherUserId.isEmpty) {
        setState(() {
          _accessState = _ConversationAccessState.unavailable;
          _conversationAccessMessage =
              'Nao foi possivel carregar os dados desta conversa.';
        });
        return;
      }

      final createResult = await repository.getOrCreateConversation(
        myUid: user.uid,
        otherUid: _otherUserId,
        otherUserName: _otherUserName,
        otherUserPhoto: _otherUserPhoto,
        myName: user.appDisplayName.isNotEmpty
            ? user.appDisplayName
            : (user.nome ?? 'Usuario'),
        myPhoto: user.foto,
      );
      if (!mounted) return;

      await createResult.fold(
        (failure) async {
          if (!mounted) return;
          setState(() {
            _accessState = _ConversationAccessState.forbidden;
            _conversationAccessMessage = _mapConversationFailureToMessage(
              failure.message,
            );
          });
        },
        (conversationId) async {
          if (!mounted) return;
          if (conversationId != widget.conversationId) {
            setState(() {
              _accessState = _ConversationAccessState.unavailable;
              _conversationAccessMessage =
                  'Nao foi possivel abrir esta conversa agora.';
            });
            return;
          }

          setState(() {
            _accessState = _ConversationAccessState.ready;
            _conversationAccessMessage = null;
          });
          unawaited(_markConversationAsRead(repository, user.uid));
          _startRealtimeReadReceiptListener(user.uid, repository);
        },
      );
    } catch (e, stack) {
      AppLogger.error('Erro ao preparar conversa', e, stack);
      if (mounted) {
        setState(() {
          _accessState = _ConversationAccessState.unavailable;
          _conversationAccessMessage =
              'Erro ao abrir conversa. Tente novamente.';
        });
      }
    }
  }

  bool _isUserParticipant(DocumentSnapshot doc, String uid) {
    final data = doc.data();
    if (data is! Map<String, dynamic>) return false;

    final participantsRaw = data['participants'];
    if (participantsRaw is! List) return false;

    return participantsRaw.any((participant) => participant == uid);
  }

  Future<void> _markConversationAsRead(
    ChatRepository repository,
    String myUid,
  ) async {
    final result = await repository.markAsRead(
      conversationId: widget.conversationId,
      myUid: myUid,
    );

    result.fold(
      (failure) => AppLogger.warning(
        'Falha ao marcar conversa como lida',
        failure.message,
      ),
      (_) {},
    );
  }

  void _startRealtimeReadReceiptListener(
    String myUid,
    ChatRepository repository,
  ) {
    _messagesReadReceiptSubscription?.close();
    _messagesReadReceiptSubscription = ref
        .listenManual<AsyncValue<List<Message>>>(
          conversationMessagesProvider(widget.conversationId),
          (previous, next) {
            final nextMessages = next.asData?.value;
            if (nextMessages == null || nextMessages.isEmpty) return;
            final latestMessage = nextMessages.first;
            if (latestMessage.senderId == myUid) return;

            final previousMessages = previous?.asData?.value;
            final previousLatestId =
                previousMessages == null || previousMessages.isEmpty
                ? null
                : previousMessages.first.id;
            if (previousLatestId == latestMessage.id) return;

            unawaited(_markConversationAsRead(repository, myUid));
          },
        );
  }

  String _mapConversationFailureToMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();

    if (lower.contains('permission-denied')) {
      return 'Conversa indisponivel no momento.';
    }

    if (lower.contains('not-found')) {
      return 'Conversa nao encontrada.';
    }

    return 'Nao foi possivel abrir esta conversa agora.';
  }

  @override
  void dispose() {
    PushNotificationService.setActiveConversation(null);
    _messagesReadReceiptSubscription?.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _canSendMessageWithVerifiedEmail() async {
    final now = DateTime.now();
    if (_cachedEmailSendAllowed != null && _cachedEmailCheckAt != null) {
      final ttl = _cachedEmailSendAllowed == true
          ? _verifiedEmailCacheTtl
          : _unverifiedEmailCacheTtl;
      final isCacheValid = now.difference(_cachedEmailCheckAt!) < ttl;
      if (isCacheValid) {
        if (_cachedEmailSendAllowed == true) return true;
        _showNeedEmailVerificationSnackbar();
        return false;
      }
    }

    final authRepository = ref.read(authRepositoryProvider);

    if (authRepository.isCurrentUserEmailVerified) {
      _cacheEmailSendPermission(true);
      return true;
    }

    bool isEmailVerified;
    try {
      isEmailVerified = await authRepository.isEmailVerified();
    } catch (e) {
      AppLogger.error('Erro ao validar verificacao de email no chat', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nao foi possivel validar seu email agora. Tente novamente.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }

    _cacheEmailSendPermission(isEmailVerified);
    if (isEmailVerified) return true;

    _showNeedEmailVerificationSnackbar();
    return false;
  }

  void _cacheEmailSendPermission(bool allowed) {
    _cachedEmailSendAllowed = allowed;
    _cachedEmailCheckAt = DateTime.now();
  }

  void _clearEmailSendCache() {
    _cachedEmailSendAllowed = null;
    _cachedEmailCheckAt = null;
  }

  bool _isPermissionDeniedFailure(String message) {
    return message.toLowerCase().contains('permission-denied');
  }

  Future<bool> _tryRefreshEmailTokenForRetry() async {
    final authRepository = ref.read(authRepositoryProvider);

    bool emailVerified = authRepository.isCurrentUserEmailVerified;
    if (!emailVerified) {
      try {
        emailVerified = await authRepository.isEmailVerified();
      } catch (e) {
        AppLogger.warning('Falha ao recarregar status de email para retry', e);
        return false;
      }
    }

    if (!emailVerified) {
      _cacheEmailSendPermission(false);
      _showNeedEmailVerificationSnackbar();
      return false;
    }

    try {
      final tokenSynced = await authRepository.hasVerifiedEmailTokenClaim(
        forceRefresh: true,
      );
      _cacheEmailSendPermission(tokenSynced);
      if (tokenSynced) return true;
    } catch (e) {
      AppLogger.warning('Falha ao atualizar token verificado para retry', e);
    }

    _showEmailSyncPendingSnackbar();
    return false;
  }

  String _addPendingMessage(String text) {
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _pendingMessages.insert(
        0,
        _PendingMessage(
          localId: localId,
          text: text,
          createdAt: DateTime.now(),
        ),
      );
    });
    return localId;
  }

  void _removePendingMessage(String localId) {
    if (!mounted) return;
    setState(() {
      _pendingMessages.removeWhere((message) => message.localId == localId);
    });
  }

  void _restoreDraftIfInputEmpty(String text) {
    if (_textController.text.trim().isNotEmpty) return;
    _textController.text = text;
    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );
  }

  void _scrollToLatestMessage() {
    if (!_scrollController.hasClients) return;
    _scrollController
        .animateTo(
          0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        )
        .ignore();
  }

  void _showNeedEmailVerificationSnackbar() {
    if (!mounted) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Verifique seu email para enviar mensagens.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Verificar',
          onPressed: () {
            if (!mounted || _isNavigatingToEmailVerification) return;

            final router = GoRouter.of(context);
            final currentPath =
                router.routerDelegate.currentConfiguration.uri.path;
            if (currentPath == RoutePaths.emailVerification) {
              return;
            }

            setState(() {
              _isNavigatingToEmailVerification = true;
            });

            context.push(RoutePaths.emailVerification).whenComplete(() {
              if (!mounted) return;

              _clearEmailSendCache();
              setState(() {
                _isNavigatingToEmailVerification = false;
              });
            });
          },
        ),
      ),
    );
  }

  void _showEmailSyncPendingSnackbar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Email verificado. Aguarde alguns segundos para sincronizar e tente novamente.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  String _resolveOtherUid(String myUid) {
    if (_otherUserId.isNotEmpty && _otherUserId != myUid) {
      return _otherUserId;
    }

    final parts = widget.conversationId.split('_');
    if (parts.length == 2) {
      if (parts[0] == myUid) return parts[1];
      if (parts[1] == myUid) return parts[0];
    }

    return '';
  }

  Future<void> _sendMessage() async {
    if (!_canReadConversation) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _conversationAccessMessage ?? 'Conversa indisponivel no momento.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty || text.length > 1000) return;

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    final otherUid = _resolveOtherUid(user.uid);
    if (otherUid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Participantes da conversa invalidos.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!await _canSendMessageWithVerifiedEmail()) return;

    final localMessageId = _addPendingMessage(text);

    // Optimistic UX: clear instantly and send in background.
    _textController.clear();
    _scrollToLatestMessage();

    unawaited(
      _sendMessageInBackground(
        localMessageId: localMessageId,
        text: text,
        myUid: user.uid,
        otherUid: otherUid,
      ),
    );
  }

  Future<void> _sendMessageInBackground({
    required String localMessageId,
    required String text,
    required String myUid,
    required String otherUid,
  }) async {
    try {
      final repository = ref.read(chatRepositoryProvider);
      Future<String?> attemptSend() async {
        final result = await repository.sendMessage(
          conversationId: widget.conversationId,
          text: text,
          myUid: myUid,
          otherUid: otherUid,
          clientMessageId: localMessageId,
        );
        return result.fold((failure) => failure.message, (_) => null);
      }

      var failureMessage = await attemptSend();
      if (failureMessage != null &&
          _isPermissionDeniedFailure(failureMessage) &&
          await _tryRefreshEmailTokenForRetry()) {
        failureMessage = await attemptSend();
      }

      if (!mounted) return;

      if (failureMessage == null) {
        _removePendingMessage(localMessageId);
        return;
      }

      _removePendingMessage(localMessageId);
      _restoreDraftIfInputEmpty(text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar mensagem: $failureMessage'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _removePendingMessage(localMessageId);
      _restoreDraftIfInputEmpty(text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar mensagem: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario nao autenticado')),
      );
    }

    final messagesAsync = _canReadConversation
        ? ref.watch(conversationMessagesProvider(widget.conversationId))
        : null;

    final conversationAsync = _canReadConversation
        ? ref.watch(conversationStreamProvider(widget.conversationId))
        : null;

    final conversationData = conversationAsync?.value?.data();
    final conversationMap = conversationData is Map<String, dynamic>
        ? conversationData
        : null;

    final participants = List<String>.from(
      conversationMap?['participants'] ?? const <String>[],
    );

    final otherUid = participants.firstWhere(
      (uid) => uid != user.uid,
      orElse: () => '',
    );

    final readUntilRaw = conversationMap?['readUntil'];
    final readUntilMap = readUntilRaw is Map
        ? Map<String, dynamic>.from(readUntilRaw)
        : const <String, dynamic>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: _buildAppBarTitle(), showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: _accessState == _ConversationAccessState.checking
                ? _buildLoadingShimmer()
                : _accessState != _ConversationAccessState.ready
                ? _buildConversationUnavailableState()
                : messagesAsync!.when(
                    data: (messages) {
                      final serverClientMessageIds = messages
                          .map((message) => message.clientMessageId)
                          .whereType<String>()
                          .toSet();

                      final pendingMessages = _pendingMessages
                          .where(
                            (pending) => !serverClientMessageIds.contains(
                              pending.localId,
                            ),
                          )
                          .map(
                            (pending) => Message(
                              id: pending.localId,
                              senderId: user.uid,
                              text: pending.text,
                              createdAt: Timestamp.fromDate(pending.createdAt),
                              clientMessageId: pending.localId,
                            ),
                          )
                          .toList(growable: false);
                      final mergedMessages = <Message>[
                        ...pendingMessages,
                        ...messages,
                      ];

                      if (mergedMessages.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhuma mensagem ainda\nEnvie a primeira!',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: AppSpacing.all16,
                        itemCount: mergedMessages.length,
                        itemBuilder: (context, index) {
                          final message = mergedMessages[index];
                          final isMe = message.senderId == user.uid;
                          final isPending = message.id.startsWith('local_');

                          bool isRead = false;
                          if (isMe && otherUid.isNotEmpty) {
                            final readUntil = readUntilMap[otherUid];
                            if (readUntil is Timestamp) {
                              isRead =
                                  readUntil.compareTo(message.createdAt) >= 0;
                            }
                          }

                          return _MessageBubble(
                            message: message,
                            isMe: isMe,
                            isPending: isPending,
                            isRead: isRead,
                          );
                        },
                      );
                    },
                    loading: () => const _ChatShimmer(),
                    error: (error, stack) {
                      AppLogger.error(
                        'Error loading messages for conversation ${widget.conversationId}',
                        error,
                      );
                      return const Center(
                        child: Text('Erro ao carregar mensagens'),
                      );
                    },
                  ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return GestureDetector(
      onTap: () {
        if (_otherUserId.isNotEmpty) {
          context.push('/user/$_otherUserId');
        }
      },
      child: Row(
        children: [
          UserAvatar(size: 36, photoUrl: _otherUserPhoto, name: _otherUserName),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              _otherUserName,
              style: AppTypography.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    final canInteract = _canReadConversation;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.s12,
        right: AppSpacing.s12,
        top: AppSpacing.s8,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AppTextField(
              controller: _textController,
              readOnly: !canInteract,
              canRequestFocus: _canReadConversation,
              maxLength: 1000,
              showCounter: false,
              maxLines: 5,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              hint: _canReadConversation
                  ? 'Mensagem...'
                  : 'Conversa indisponivel',
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textController,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;

              return GestureDetector(
                onTap: canInteract && hasText ? _sendMessage : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: hasText && _canReadConversation
                        ? AppColors.primary
                        : AppColors.surfaceHighlight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: hasText && _canReadConversation
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return const _ChatShimmer();
  }

  Widget _buildConversationUnavailableState() {
    return Center(
      child: Padding(
        padding: AppSpacing.h24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.s12),
            Text(
              _conversationAccessMessage ??
                  'Nao foi possivel acessar esta conversa.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isPending;
  final bool isRead;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.isPending = false,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.r24),
                topRight: const Radius.circular(AppRadius.r24),
                bottomLeft: isMe
                    ? const Radius.circular(AppRadius.r24)
                    : const Radius.circular(AppRadius.r4),
                bottomRight: isMe
                    ? const Radius.circular(AppRadius.r4)
                    : const Radius.circular(AppRadius.r24),
              ),
              border: !isMe
                  ? Border.all(
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt.toDate().toLocal()),
                      style: AppTypography.chipLabel.copyWith(
                        color: isMe
                            ? AppColors.textPrimary.withValues(alpha: 0.7)
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: AppSpacing.s4),
                      if (isPending)
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textPrimary.withValues(alpha: 0.7),
                        )
                      else
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead
                              ? AppColors.textPrimary
                              : AppColors.textPrimary.withValues(alpha: 0.7),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatShimmer extends StatelessWidget {
  const _ChatShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.all16,
      itemCount: 8,
      reverse: true,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s16),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  AppShimmer.box(
                    width: index % 3 == 0 ? 150 : 200,
                    height: 48,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  AppShimmer.text(width: 40, height: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
