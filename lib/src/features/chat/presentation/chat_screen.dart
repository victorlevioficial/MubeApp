import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../design_system/components/data_display/user_avatar.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/loading/app_shimmer.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/app_performance_tracker.dart';
import '../../auth/data/auth_repository.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';
import '../data/chat_safety_repository.dart';
import '../domain/chat_content_analyzer.dart';
import '../domain/conversation_preview.dart';
import '../domain/message.dart';

part 'chat_screen_widgets.dart';

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
  final List<Message> _olderServerMessages = <Message>[];
  ProviderSubscription<AsyncValue<QuerySnapshot<Map<String, dynamic>>>>?
  _messagesReadReceiptSubscription;
  ProviderSubscription<AsyncValue<List<ConversationPreview>>>?
  _conversationPreviewSubscription;
  bool _isNavigatingToEmailVerification = false;
  bool _isPreparingConversation = false;
  bool _isLoadingOlderMessages = false;
  bool _hasMoreOlderMessages = false;
  _ConversationAccessState _accessState = _ConversationAccessState.checking;
  String? _conversationAccessMessage;
  bool? _cachedEmailSendAllowed;
  DateTime? _cachedEmailCheckAt;
  DocumentSnapshot<Map<String, dynamic>>? _oldestServerMessageDoc;

  // Dados do outro usuario (pode vir via extra ou cache local)
  late String _otherUserName;
  String? _otherUserPhoto;
  late String _otherUserId;

  bool get _canReadConversation =>
      _accessState == _ConversationAccessState.ready;

  static const Duration _verifiedEmailCacheTtl = Duration(minutes: 5);
  static const Duration _unverifiedEmailCacheTtl = Duration(seconds: 8);
  static const int _messagesPageSize = 50;
  static const double _paginationTriggerDistance = 240;
  late final Stopwatch _firstMessagesFrameStopwatch;
  bool _hasFinishedFirstMessagesFrameSpan = false;

  bool get _hasKnownConversationContext =>
      _otherUserId.isNotEmpty || _hasCachedConversationPreview();

  @override
  void initState() {
    super.initState();
    PushNotificationService.setActiveConversation(widget.conversationId);
    _scrollController.addListener(_handleMessagesScroll);

    _initializeData();
    _firstMessagesFrameStopwatch = AppPerformanceTracker.startSpan(
      'chat.open.first_messages_frame',
      data: {
        'conversation_id': widget.conversationId,
        'has_cached_preview': _hasCachedConversationPreview(),
        'has_other_user_hint': _otherUserId.isNotEmpty,
      },
    );
    if (_hasKnownConversationContext) {
      _accessState = _ConversationAccessState.ready;
    }
    _setupConversationPreviewListener();
    unawaited(_prepareConversation());
  }

  void _setupConversationPreviewListener() {
    _conversationPreviewSubscription = ref
        .listenManual<AsyncValue<List<ConversationPreview>>>(
          userConversationsProvider,
          (_, next) {
            final previews = next.asData?.value;
            if (previews == null) return;
            final updated = previews
                .where((p) => p.id == widget.conversationId)
                .firstOrNull;
            if (updated == null) return;
            if (updated.otherUserPhoto != _otherUserPhoto ||
                updated.otherUserName != _otherUserName) {
              if (mounted) {
                setState(() {
                  _otherUserPhoto = updated.otherUserPhoto;
                  _otherUserName = updated.otherUserName;
                  if (_otherUserId.isEmpty) {
                    _otherUserId = updated.otherUserId;
                  }
                });
              }
            }
          },
        );
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

  bool _hasCachedConversationPreview() {
    return ref
            .read(userConversationsProvider)
            .value
            ?.any((preview) => preview.id == widget.conversationId) ??
        false;
  }

  void _setConversationReady({
    required String myUid,
    required ChatRepository repository,
    bool markAsRead = false,
  }) {
    if (mounted &&
        (_accessState != _ConversationAccessState.ready ||
            _conversationAccessMessage != null)) {
      setState(() {
        _accessState = _ConversationAccessState.ready;
        _conversationAccessMessage = null;
      });
    }

    _startRealtimeReadReceiptListener(myUid, repository);
    if (markAsRead) {
      unawaited(_markConversationAsRead(repository, myUid));
    }
  }

  Future<void> _prepareConversation() async {
    if (_isPreparingConversation) return;
    _isPreparingConversation = true;
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      _isPreparingConversation = false;
      return;
    }

    final repository = ref.read(chatRepositoryProvider);
    final prepareConversationStopwatch = AppPerformanceTracker.startSpan(
      'chat.prepare_conversation',
      data: {
        'conversation_id': widget.conversationId,
        'has_cached_preview': _hasCachedConversationPreview(),
        'has_other_user_hint': _otherUserId.isNotEmpty,
      },
    );
    var outcome = 'unknown';

    try {
      final existingDoc = await repository.getConversationDoc(
        widget.conversationId,
      );
      if (!mounted) return;

      if (existingDoc != null && existingDoc.exists) {
        if (!_isUserParticipant(existingDoc, user.uid)) {
          outcome = 'forbidden_not_participant';
          setState(() {
            _accessState = _ConversationAccessState.forbidden;
            _conversationAccessMessage =
                'Você não tem permissão para acessar esta conversa.';
          });
          _finishFirstMessagesFrameSpan(status: 'forbidden', renderedCount: 0);
          return;
        }

        final otherUid = _resolveConversationParticipant(existingDoc, user.uid);
        if (otherUid.isEmpty) {
          outcome = 'unavailable_missing_participant';
          setState(() {
            _accessState = _ConversationAccessState.unavailable;
            _conversationAccessMessage =
                'Não foi possível carregar os participantes da conversa.';
          });
          _finishFirstMessagesFrameSpan(
            status: 'unavailable_missing_participant',
            renderedCount: 0,
          );
          return;
        }

        setState(() {
          _otherUserId = otherUid;
        });

        _setConversationReady(
          myUid: user.uid,
          repository: repository,
          markAsRead: true,
        );

        if (!_hasCachedConversationPreview()) {
          unawaited(
            _restoreConversationPreview(
              repository: repository,
              myUid: user.uid,
              otherUid: otherUid,
            ),
          );
        }
        outcome = 'existing_conversation';
        return;
      }

      if (_otherUserId.isEmpty) {
        outcome = 'unavailable_missing_other_uid';
        setState(() {
          _accessState = _ConversationAccessState.unavailable;
          _conversationAccessMessage =
              'Não foi possível carregar os dados desta conversa.';
        });
        _finishFirstMessagesFrameSpan(
          status: 'unavailable_missing_other_uid',
          renderedCount: 0,
        );
        return;
      }

      _setConversationReady(
        myUid: user.uid,
        repository: repository,
        markAsRead: false,
      );
      outcome = 'draft_conversation';
    } catch (e, stack) {
      outcome = 'error';
      AppLogger.error('Erro ao preparar conversa', e, stack);
      if (mounted) {
        setState(() {
          _accessState = _ConversationAccessState.unavailable;
          _conversationAccessMessage =
              'Erro ao abrir conversa. Tente novamente.';
        });
      }
      _finishFirstMessagesFrameSpan(status: 'prepare_error', renderedCount: 0);
    } finally {
      AppPerformanceTracker.finishSpan(
        'chat.prepare_conversation',
        prepareConversationStopwatch,
        data: {'conversation_id': widget.conversationId, 'outcome': outcome},
      );
      _isPreparingConversation = false;
    }
  }

  Future<void> _restoreConversationPreview({
    required ChatRepository repository,
    required String myUid,
    required String otherUid,
  }) async {
    final restorePreviewStopwatch = AppPerformanceTracker.startSpan(
      'chat.restore_preview',
      data: {'conversation_id': widget.conversationId},
    );
    final result = await repository.restoreConversationPreview(
      conversationId: widget.conversationId,
      myUid: myUid,
      otherUid: otherUid,
      fallbackOtherUserName: _otherUserName,
      fallbackOtherUserPhoto: _otherUserPhoto,
    );

    result.fold(
      (failure) {
        AppPerformanceTracker.finishSpan(
          'chat.restore_preview',
          restorePreviewStopwatch,
          data: {'conversation_id': widget.conversationId, 'outcome': 'error'},
        );
        AppLogger.warning(
          'Falha ao restaurar preview da conversa',
          failure.message,
        );
      },
      (_) {
        AppPerformanceTracker.finishSpan(
          'chat.restore_preview',
          restorePreviewStopwatch,
          data: {
            'conversation_id': widget.conversationId,
            'outcome': 'success',
          },
        );
      },
    );
  }

  void _finishFirstMessagesFrameSpan({
    QuerySnapshot<Map<String, dynamic>>? snapshot,
    required int renderedCount,
    String? status,
  }) {
    if (_hasFinishedFirstMessagesFrameSpan) return;
    _hasFinishedFirstMessagesFrameSpan = true;
    AppPerformanceTracker.finishSpan(
      'chat.open.first_messages_frame',
      _firstMessagesFrameStopwatch,
      data: {
        'conversation_id': widget.conversationId,
        'status': status,
        'source': snapshot == null
            ? null
            : (snapshot.metadata.isFromCache ? 'cache' : 'server'),
        'snapshot_size': snapshot?.docs.length,
        'rendered_count': renderedCount,
        'has_pending_writes': snapshot?.metadata.hasPendingWrites,
      },
    );
  }

  bool _isUserParticipant(DocumentSnapshot doc, String uid) {
    final data = doc.data();
    if (data is! Map<String, dynamic>) return false;

    final participantsRaw = data['participants'];
    if (participantsRaw is! List) return false;

    return participantsRaw.any((participant) => participant == uid);
  }

  String _resolveConversationParticipant(DocumentSnapshot doc, String myUid) {
    final data = doc.data();
    if (data is! Map<String, dynamic>) return '';

    final participantsRaw = data['participants'];
    if (participantsRaw is! List) return '';

    for (final participant in participantsRaw) {
      if (participant is String && participant != myUid) {
        return participant;
      }
    }

    return '';
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
        .listenManual<AsyncValue<QuerySnapshot<Map<String, dynamic>>>>(
          conversationMessagesSnapshotProvider(widget.conversationId),
          (previous, next) {
            final nextSnapshot = next.asData?.value;
            if (nextSnapshot == null) return;

            _syncPaginationStateFromLatestSnapshot(nextSnapshot);

            final nextMessages = _messagesFromSnapshot(nextSnapshot);
            if (nextMessages.isEmpty) return;
            final latestMessage = nextMessages.first;
            if (latestMessage.senderId == myUid) return;

            final previousSnapshot = previous?.asData?.value;
            final previousMessages = previousSnapshot == null
                ? null
                : _messagesFromSnapshot(previousSnapshot);
            final previousLatestId =
                previousMessages == null || previousMessages.isEmpty
                ? null
                : previousMessages.first.id;
            if (previousLatestId == latestMessage.id) return;

            unawaited(_markConversationAsRead(repository, myUid));
          },
        );
  }

  List<Message> _messagesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => Message.fromFirestore(doc))
        .toList(growable: false);
  }

  void _syncPaginationStateFromLatestSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!mounted) return;
    if (_olderServerMessages.isNotEmpty) return;

    if (snapshot.docs.isEmpty) {
      if (_oldestServerMessageDoc != null || _hasMoreOlderMessages) {
        setState(() {
          _oldestServerMessageDoc = null;
          _hasMoreOlderMessages = false;
        });
      }
      return;
    }

    final newOldestDoc = snapshot.docs.last;
    final hasMore = snapshot.docs.length >= _messagesPageSize;
    final hasCursorChanged = _oldestServerMessageDoc?.id != newOldestDoc.id;

    if (!hasCursorChanged && _hasMoreOlderMessages == hasMore) return;

    setState(() {
      _oldestServerMessageDoc = newOldestDoc;
      _hasMoreOlderMessages = hasMore;
    });
  }

  void _handleMessagesScroll() {
    if (!_canReadConversation) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final distanceToOldest = position.maxScrollExtent - position.pixels;
    if (distanceToOldest > _paginationTriggerDistance) return;

    unawaited(_loadOlderMessages());
  }

  Future<void> _loadOlderMessages() async {
    if (!_canReadConversation) return;
    if (_isLoadingOlderMessages || !_hasMoreOlderMessages) return;

    final cursor = _oldestServerMessageDoc;
    if (cursor == null) return;

    setState(() {
      _isLoadingOlderMessages = true;
    });

    final repository = ref.read(chatRepositoryProvider);

    try {
      final page = await repository.getMessagesPage(
        conversationId: widget.conversationId,
        startAfterDoc: cursor,
      );

      if (!mounted) return;

      final existingIds = _olderServerMessages
          .map((message) => message.id)
          .toSet();
      final freshMessages = page.messages
          .where((message) => !existingIds.contains(message.id))
          .toList(growable: false);

      setState(() {
        _olderServerMessages.addAll(freshMessages);
        if (page.lastVisibleDoc != null) {
          _oldestServerMessageDoc = page.lastVisibleDoc;
        }
        _hasMoreOlderMessages = page.hasMore;
        _isLoadingOlderMessages = false;
      });
    } catch (e, stack) {
      AppLogger.error('Erro ao carregar mensagens antigas', e, stack);
      if (!mounted) return;

      setState(() {
        _isLoadingOlderMessages = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao carregar mensagens antigas.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<Message> _mergeServerMessages(List<Message> latestMessages) {
    final merged = <Message>[];
    final seenIds = <String>{};

    for (final message in latestMessages) {
      if (seenIds.add(message.id)) {
        merged.add(message);
      }
    }

    for (final message in _olderServerMessages) {
      if (seenIds.add(message.id)) {
        merged.add(message);
      }
    }

    return merged;
  }

  bool _shouldShowDateSeparator(List<Message> messages, int index) {
    if (index >= messages.length) return false;
    if (index == messages.length - 1) return true;

    final currentDate = messages[index].createdAt.toDate().toLocal();
    final olderDate = messages[index + 1].createdAt.toDate().toLocal();
    return !_isSameDay(currentDate, olderDate);
  }

  String _formatDateSeparatorLabel(DateTime dateTime) {
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayDiff = today.difference(target).inDays;

    if (dayDiff == 0) return 'Hoje';
    if (dayDiff == 1) return 'Ontem';

    return DateFormat('dd/MM/yyyy').format(target);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
              'Não foi possível validar seu email agora. Tente novamente.',
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

    final contentAnalysis = ChatContentAnalyzer.analyze(text);
    if (contentAnalysis.isSuspicious) {
      unawaited(
        ref
            .read(chatSafetyRepositoryProvider)
            .logPreSendWarning(
              conversationId: widget.conversationId,
              text: text,
              clientPatterns: contentAnalysis.patterns,
              clientChannels: contentAnalysis.channels,
              severity: contentAnalysis.severityName,
            ),
      );
      await _showChatSafetyWarning(
        contentAnalysis.warningMessage ??
            'O chat do Mube não permite compartilhar contato por aqui.',
      );
      return;
    }

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

  Future<void> _showChatSafetyWarning(String message) async {
    if (!mounted) return;

    FocusScope.of(context).unfocus();

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: 'Contato não permitido',
        message: message,
        confirmText: 'Entendi',
        cancelText: 'Editar mensagem',
        isDestructive: false,
      ),
    );
  }

  @override
  void dispose() {
    PushNotificationService.setActiveConversation(null);
    _conversationPreviewSubscription?.close();
    _messagesReadReceiptSubscription?.close();
    _scrollController.removeListener(_handleMessagesScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    if (userAsync.isLoading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario nao autenticado')),
      );
    }

    if (_accessState == _ConversationAccessState.checking &&
        !_isPreparingConversation) {
      unawaited(_prepareConversation());
    }

    final messagesSnapshotAsync = _canReadConversation
        ? ref.watch(conversationMessagesSnapshotProvider(widget.conversationId))
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
      body: _buildChatBody(
        messagesSnapshotAsync: messagesSnapshotAsync,
        currentUserId: user.uid,
        otherUid: otherUid,
        readUntilMap: readUntilMap,
      ),
    );
  }
}
