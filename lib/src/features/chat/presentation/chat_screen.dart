import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    PushNotificationService.setActiveConversation(widget.conversationId);
    _scrollController.addListener(_handleMessagesScroll);

    _initializeData();
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

  Future<void> _prepareConversation() async {
    if (_isPreparingConversation) return;
    _isPreparingConversation = true;
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      _isPreparingConversation = false;
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
                'Você não tem permissão para acessar esta conversa.';
          });
          return;
        }

        final otherUid = _resolveConversationParticipant(existingDoc, user.uid);
        if (otherUid.isEmpty) {
          setState(() {
            _accessState = _ConversationAccessState.unavailable;
            _conversationAccessMessage =
                'Não foi possível carregar os participantes da conversa.';
          });
          return;
        }

        final restoreResult = await repository.restoreConversationPreview(
          conversationId: widget.conversationId,
          myUid: user.uid,
          otherUid: otherUid,
          fallbackOtherUserName: _otherUserName,
          fallbackOtherUserPhoto: _otherUserPhoto,
        );
        if (!mounted) return;

        restoreResult.fold(
          (failure) => AppLogger.warning(
            'Falha ao restaurar preview da conversa',
            failure.message,
          ),
          (_) {},
        );

        setState(() {
          _otherUserId = otherUid;
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
              'Não foi possível carregar os dados desta conversa.';
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
                  'Não foi possível abrir esta conversa agora.';
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
    } finally {
      _isPreparingConversation = false;
    }
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

  String _mapConversationFailureToMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();

    if (lower.contains('permission-denied')) {
      return 'Conversa indisponivel no momento.';
    }

    if (lower.contains('not-found')) {
      return 'Conversa nao encontrada.';
    }

    return 'Não foi possível abrir esta conversa agora.';
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
      body: Column(
        children: [
          Expanded(
            child: _accessState == _ConversationAccessState.checking
                ? _buildLoadingShimmer()
                : _accessState != _ConversationAccessState.ready
                ? _buildConversationUnavailableState()
                : messagesSnapshotAsync!.when(
                    data: (messagesSnapshot) {
                      final latestMessages = _messagesFromSnapshot(
                        messagesSnapshot,
                      );
                      final serverMessages = _mergeServerMessages(
                        latestMessages,
                      );
                      final serverClientMessageIds = serverMessages
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
                        ...serverMessages,
                      ];
                      final showPaginationLoader =
                          _isLoadingOlderMessages || _hasMoreOlderMessages;

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
                        itemCount:
                            mergedMessages.length +
                            (showPaginationLoader ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (showPaginationLoader &&
                              index == mergedMessages.length) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.s8,
                                bottom: AppSpacing.s4,
                              ),
                              child: Center(
                                child: _isLoadingOlderMessages
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Suba para carregar mais',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                              ),
                            );
                          }

                          final message = mergedMessages[index];
                          final isMe = message.senderId == user.uid;
                          final isPending = message.id.startsWith('local_');
                          final showDateSeparator = _shouldShowDateSeparator(
                            mergedMessages,
                            index,
                          );
                          final dateLabel = showDateSeparator
                              ? _formatDateSeparatorLabel(
                                  message.createdAt.toDate().toLocal(),
                                )
                              : null;

                          bool isRead = false;
                          if (isMe && otherUid.isNotEmpty) {
                            final readUntil = readUntilMap[otherUid];
                            if (readUntil is Timestamp) {
                              isRead =
                                  readUntil.compareTo(message.createdAt) >= 0;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (dateLabel != null)
                                _DaySeparator(label: dateLabel),
                              _MessageBubble(
                                message: message,
                                isMe: isMe,
                                isPending: isPending,
                                isRead: isRead,
                              ),
                            ],
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
          context.push(RoutePaths.publicProfileById(_otherUserId));
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
              keyboardType: TextInputType.multiline,
              maxLength: 1000,
              showCounter: false,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
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
                  'Não foi possível acessar esta conversa.',
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

class _DaySeparator extends StatelessWidget {
  final String label;

  const _DaySeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8, top: AppSpacing.s8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all12,
            border: Border.all(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: AppTypography.titleSmall.fontWeight,
            ),
          ),
        ),
      ),
    );
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
