import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../design_system/components/data_display/user_avatar.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
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
  final String? replyToMessageId;
  final String? replyToSenderId;
  final String? replyToText;
  final String? replyToType;

  const _PendingMessage({
    required this.localId,
    required this.text,
    required this.createdAt,
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToText,
    this.replyToType,
  });
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const String _requestStatusAccepted = 'accepted';
  static const String _requestStatusPending = 'pending';
  static const String _requestStatusRejected = 'rejected';
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_PendingMessage> _pendingMessages = [];
  final List<Message> _olderServerMessages = <Message>[];
  Message? _replyingToMessage;
  ProviderSubscription<AsyncValue<QuerySnapshot<Map<String, dynamic>>>>?
  _messagesReadReceiptSubscription;
  ProviderSubscription<AsyncValue<List<ConversationPreview>>>?
  _conversationPreviewSubscription;
  bool _isNavigatingToEmailVerification = false;
  bool _isPreparingConversation = false;
  bool _isLoadingOlderMessages = false;
  bool _isAcceptingConversationRequest = false;
  bool _hasMoreOlderMessages = false;
  bool _conversationExists = false;
  bool _hasOptimisticAcceptedRequest = false;
  _ConversationAccessState _accessState = _ConversationAccessState.checking;
  String? _conversationAccessMessage;
  String _currentRequestStatus = _requestStatusAccepted;
  int _currentRequestCycle = 0;
  String? _currentRequestSenderId;
  String? _currentRequestRecipientId;
  bool? _cachedEmailSendAllowed;
  DateTime? _cachedEmailCheckAt;
  DateTime? _lastSendAttemptAt;
  DocumentSnapshot<Map<String, dynamic>>? _oldestServerMessageDoc;
  bool _isHydratingOtherUserPreview = false;

  // Dados do outro usuario (pode vir via extra ou cache local)
  late String _otherUserName;
  String? _otherUserPhoto;
  late String _otherUserId;
  late String _conversationType;

  bool get _canReadConversation =>
      _accessState == _ConversationAccessState.ready;

  bool get _hasPersistedConversation => _conversationExists;

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
                updated.otherUserName != _otherUserName ||
                updated.type != _conversationType) {
              if (mounted) {
                setState(() {
                  _otherUserPhoto = updated.otherUserPhoto;
                  _otherUserName = updated.otherUserName;
                  _conversationType = updated.type;
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
    final currentUserId =
        ref.read(currentUserProfileProvider).value?.uid ??
        ref.read(authStateChangesProvider).value?.uid ??
        ref.read(authRepositoryProvider).currentUser?.uid;

    _otherUserName =
        extra?['otherUserName'] ?? cachedPreview?.otherUserName ?? 'Usuario';
    _otherUserPhoto = extra?['otherUserPhoto'] ?? cachedPreview?.otherUserPhoto;
    _otherUserId = extra?['otherUserId'] ?? cachedPreview?.otherUserId ?? '';
    _conversationType =
        extra?['conversationType'] ?? cachedPreview?.type ?? 'direct';

    if (_otherUserId.isEmpty && currentUserId != null) {
      _otherUserId = _deriveOtherUidFromConversationId(currentUserId);
    }
  }

  bool _hasCachedConversationPreview() {
    return ref
            .read(userConversationsProvider)
            .value
            ?.any((preview) => preview.id == widget.conversationId) ??
        false;
  }

  String _deriveOtherUidFromConversationId(String myUid) {
    final parts = widget.conversationId.split('_');
    if (parts.length != 2) return '';
    if (parts[0] == myUid) return parts[1];
    if (parts[1] == myUid) return parts[0];
    return '';
  }

  bool _needsOtherUserPreviewHydration() {
    final normalizedName = _otherUserName.trim();
    return normalizedName.isEmpty ||
        normalizedName == 'Usuario' ||
        (_otherUserPhoto == null || _otherUserPhoto!.trim().isEmpty);
  }

  Future<void> _maybeHydrateOtherUserPreview() async {
    if (_isHydratingOtherUserPreview) return;
    if (_otherUserId.isEmpty || !_needsOtherUserPreviewHydration()) return;

    _isHydratingOtherUserPreview = true;
    try {
      final preview = await ref
          .read(chatRepositoryProvider)
          .getConversationParticipantPreview(_otherUserId);
      if (!mounted) return;

      setState(() {
        if (_otherUserName.trim().isEmpty || _otherUserName == 'Usuario') {
          _otherUserName = preview.displayName;
        }
        if ((_otherUserPhoto ?? '').trim().isEmpty &&
            (preview.photoUrl ?? '').trim().isNotEmpty) {
          _otherUserPhoto = preview.photoUrl;
        }
      });
    } finally {
      _isHydratingOtherUserPreview = false;
    }
  }

  void _setConversationReady({
    required String myUid,
    required ChatRepository repository,
    bool markAsRead = false,
    bool startReadReceiptListener = true,
  }) {
    if (mounted &&
        (_accessState != _ConversationAccessState.ready ||
            _conversationAccessMessage != null)) {
      setState(() {
        _accessState = _ConversationAccessState.ready;
        _conversationAccessMessage = null;
      });
    }

    if (startReadReceiptListener) {
      _startRealtimeReadReceiptListener(myUid, repository);
    } else {
      _messagesReadReceiptSubscription?.close();
      _messagesReadReceiptSubscription = null;
    }
    if (markAsRead) {
      unawaited(_markConversationAsRead(repository, myUid));
    }
  }

  Future<bool> _maybeRedirectToCanonicalConversationId({
    required String myUid,
    required ChatRepository repository,
  }) async {
    final otherUid = _resolveOtherUid(myUid);
    if (otherUid.isEmpty) return false;

    final canonicalConversationId = repository.getConversationId(
      myUid,
      otherUid,
    );
    if (canonicalConversationId == widget.conversationId) {
      return false;
    }

    if (!mounted) return true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.replace(
        RoutePaths.conversationById(canonicalConversationId),
        extra: {
          'otherUserId': otherUid,
          'otherUserName': _otherUserName,
          'otherUserPhoto': _otherUserPhoto,
          'conversationType': _conversationType,
        },
      );
    });

    return true;
  }

  Future<void> _prepareConversation() async {
    if (_isPreparingConversation) return;
    _isPreparingConversation = true;
    final currentUserId =
        ref.read(currentUserProfileProvider).value?.uid ??
        ref.read(authStateChangesProvider).value?.uid ??
        ref.read(authRepositoryProvider).currentUser?.uid;
    if (currentUserId == null) {
      _isPreparingConversation = false;
      return;
    }

    final repository = ref.read(chatRepositoryProvider);
    final prepareConversationStopwatch = AppPerformanceTracker.startSpan(
      'chat.prepare_conversation',
      data: {
        'conversation_id': widget.conversationId,
        'current_user_id': currentUserId,
        'has_cached_preview': _hasCachedConversationPreview(),
        'has_other_user_hint': _otherUserId.isNotEmpty,
      },
    );
    var outcome = 'unknown';

    try {
      final resolvedOtherUid = _otherUserId.isNotEmpty
          ? _otherUserId
          : _deriveOtherUidFromConversationId(currentUserId);
      if (resolvedOtherUid.isNotEmpty) {
        if (mounted && resolvedOtherUid != _otherUserId) {
          setState(() {
            _otherUserId = resolvedOtherUid;
          });
        }

        if (await _maybeRedirectToCanonicalConversationId(
          myUid: currentUserId,
          repository: repository,
        )) {
          outcome = 'redirect_noncanonical_id';
          return;
        }

        _setConversationReady(
          myUid: currentUserId,
          repository: repository,
          markAsRead: false,
          startReadReceiptListener: false,
        );
        unawaited(_maybeHydrateOtherUserPreview());
      }

      final existingDoc = await repository.getConversationDoc(
        widget.conversationId,
      );
      if (!mounted) return;

      if (existingDoc != null && existingDoc.exists) {
        unawaited(
          repository.reevaluateConversationAccess(
            conversationId: widget.conversationId,
            trigger: 'open_chat',
          ),
        );

        if (!_isUserParticipant(existingDoc, currentUserId)) {
          outcome = 'forbidden_not_participant';
          setState(() {
            _accessState = _ConversationAccessState.forbidden;
            _conversationAccessMessage =
                'Você não tem permissão para acessar esta conversa.';
          });
          _finishFirstMessagesFrameSpan(status: 'forbidden', renderedCount: 0);
          return;
        }

        final otherUid = _resolveConversationParticipant(
          existingDoc,
          currentUserId,
        );
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
          _conversationExists = true;
        });
        unawaited(_maybeHydrateOtherUserPreview());

        _setConversationReady(
          myUid: currentUserId,
          repository: repository,
          markAsRead: true,
          startReadReceiptListener: true,
        );

        if (!_hasCachedConversationPreview()) {
          unawaited(
            _restoreConversationPreview(
              repository: repository,
              myUid: currentUserId,
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

      if (mounted && _conversationExists) {
        setState(() {
          _conversationExists = false;
        });
      }

      _setConversationReady(
        myUid: currentUserId,
        repository: repository,
        markAsRead: false,
        startReadReceiptListener: false,
      );
      outcome = 'draft_conversation';
    } on FirebaseException catch (e, stack) {
      outcome = 'firebase_${e.code}';
      AppLogger.error(
        'Erro ao preparar conversa | conversationId=${widget.conversationId} | '
        'currentUserId=$currentUserId | otherUserId=$_otherUserId | '
        'hasCachedPreview=${_hasCachedConversationPreview()}',
        e,
        stack,
      );
      if (mounted) {
        setState(() {
          if (e.code == 'permission-denied') {
            _accessState = _ConversationAccessState.forbidden;
            _conversationAccessMessage =
                'Você não tem permissão para acessar esta conversa.';
          } else {
            _accessState = _ConversationAccessState.unavailable;
            _conversationAccessMessage =
                'Erro ao abrir conversa. Tente novamente.';
          }
        });
      }
      _finishFirstMessagesFrameSpan(
        status: 'prepare_firebase_error',
        renderedCount: 0,
      );
    } catch (e, stack) {
      outcome = 'error';
      AppLogger.error(
        'Erro ao preparar conversa | conversationId=${widget.conversationId} | '
        'currentUserId=$currentUserId | otherUserId=$_otherUserId | '
        'hasCachedPreview=${_hasCachedConversationPreview()}',
        e,
        stack,
      );
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

      AppSnackBar.error(context, 'Erro ao carregar mensagens antigas.');
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
        AppSnackBar.error(
          context,
          'Nao foi possivel validar seu email agora. Tente novamente.',
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

  String _addPendingMessage(String text, {Message? replyToMessage}) {
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _pendingMessages.insert(
        0,
        _PendingMessage(
          localId: localId,
          text: text,
          createdAt: DateTime.now(),
          replyToMessageId: replyToMessage?.id,
          replyToSenderId: replyToMessage?.senderId,
          replyToText: replyToMessage?.text,
          replyToType: replyToMessage?.type,
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

  void _restoreDraftIfInputEmpty(String text, {Message? replyToMessage}) {
    if (_textController.text.trim().isNotEmpty) return;
    if (mounted) {
      setState(() {
        _replyingToMessage = replyToMessage;
      });
    } else {
      _replyingToMessage = replyToMessage;
    }
    _textController.text = text;
    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );
  }

  void _setReplyTarget(Message message) {
    if (!mounted) return;
    setState(() {
      _replyingToMessage = message;
    });
  }

  void _clearReplyTarget() {
    if (!mounted) return;
    setState(() {
      _replyingToMessage = null;
    });
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
    AppSnackBar.action(
      context,
      'Verifique seu email para enviar mensagens.',
      type: SnackBarType.warning,
      actionLabel: 'Verificar',
      duration: const Duration(seconds: 5),
      onAction: () {
        if (!mounted || _isNavigatingToEmailVerification) return;

        final router = GoRouter.of(context);
        final currentPath = router.routerDelegate.currentConfiguration.uri.path;
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
    );
  }

  void _showEmailSyncPendingSnackbar() {
    if (!mounted) return;

    AppSnackBar.info(
      context,
      'Email verificado. Aguarde alguns segundos para sincronizar e tente novamente.',
    );
  }

  String _resolveOtherUid(String myUid) {
    if (_otherUserId.isNotEmpty && _otherUserId != myUid) {
      return _otherUserId;
    }
    return _deriveOtherUidFromConversationId(myUid);
  }

  String _readRequestStatus(Map<String, dynamic>? conversationMap) {
    final value = conversationMap?['requestStatus'];
    if (value is String &&
        (value == _requestStatusAccepted ||
            value == _requestStatusPending ||
            value == _requestStatusRejected)) {
      return value;
    }
    return _requestStatusAccepted;
  }

  int _readRequestCycle(Map<String, dynamic>? conversationMap) {
    final value = conversationMap?['requestCycle'];
    if (value is num) return value.toInt();
    return 0;
  }

  String? _readOptionalString(dynamic value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _syncConversationRequestState(Map<String, dynamic>? conversationMap) {
    final backendStatus = _readRequestStatus(conversationMap);
    final backendCycle = _readRequestCycle(conversationMap);
    final backendSenderId = _readOptionalString(
      conversationMap?['requestSenderId'],
    );
    final backendRecipientId = _readOptionalString(
      conversationMap?['requestRecipientId'],
    );

    if (_hasOptimisticAcceptedRequest) {
      _currentRequestStatus = _requestStatusAccepted;
      _currentRequestCycle = backendCycle;
      _currentRequestSenderId = null;
      _currentRequestRecipientId = null;

      if (backendStatus == _requestStatusAccepted) {
        _hasOptimisticAcceptedRequest = false;
      }
      return;
    }

    _currentRequestStatus = backendStatus;
    _currentRequestCycle = backendCycle;
    _currentRequestSenderId = backendSenderId;
    _currentRequestRecipientId = backendRecipientId;
  }

  bool _isPendingRecipient(String currentUserId) {
    return _currentRequestStatus == _requestStatusPending &&
        _currentRequestRecipientId == currentUserId;
  }

  void _invalidateConversationProviders() {
    ref.invalidate(userConversationsProvider);
    ref.invalidate(userAcceptedConversationsProvider);
    ref.invalidate(userPendingConversationsProvider);
  }

  Future<void> _maybeShowPendingRequestSnackbarAfterSend({
    required ChatRepository repository,
    required String myUid,
    required String previousRequestStatus,
    required int previousRequestCycle,
    required String? previousRequestSenderId,
  }) async {
    final alreadyPendingOutgoing =
        previousRequestStatus == _requestStatusPending &&
        previousRequestSenderId == myUid;
    if (alreadyPendingOutgoing) return;

    try {
      final snapshot = await repository.getConversationDoc(
        widget.conversationId,
      );
      final data = snapshot?.data();
      final conversationMap = data is Map<String, dynamic> ? data : null;
      final requestStatus = _readRequestStatus(conversationMap);
      final requestCycle = _readRequestCycle(conversationMap);
      final requestSenderId = _readOptionalString(
        conversationMap?['requestSenderId'],
      );

      if (!mounted) return;
      if (requestStatus == _requestStatusPending &&
          requestSenderId == myUid &&
          requestCycle != previousRequestCycle) {
        AppSnackBar.info(context, 'Mensagem enviada para Solicitacoes.');
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Falha ao verificar status pendente apos envio da mensagem',
        '$e\n$stack',
      );
    }
  }

  Future<void> _acceptConversationRequest({
    required String myUid,
    required String otherUid,
  }) async {
    if (_isAcceptingConversationRequest) return;

    setState(() {
      _isAcceptingConversationRequest = true;
    });

    final result = await ref
        .read(chatRepositoryProvider)
        .acceptConversationRequest(
          conversationId: widget.conversationId,
          myUid: myUid,
          otherUid: otherUid,
        );

    if (!mounted) return;

    var accepted = false;
    result.fold(
      (failure) => AppSnackBar.error(
        context,
        'Erro ao aceitar solicitacao: ${failure.message}',
      ),
      (_) {
        accepted = true;
        AppSnackBar.success(
          context,
          'Solicitacao aceita. Voce ja pode responder.',
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _isAcceptingConversationRequest = false;
      if (accepted) {
        _hasOptimisticAcceptedRequest = true;
        _currentRequestStatus = _requestStatusAccepted;
        _currentRequestSenderId = null;
        _currentRequestRecipientId = null;
      }
    });

    if (accepted) {
      _invalidateConversationProviders();
    }
  }

  Future<void> _sendMessage() async {
    if (!_canReadConversation) {
      if (mounted) {
        AppSnackBar.error(
          context,
          _conversationAccessMessage ?? 'Conversa indisponivel no momento.',
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

    final myUid =
        ref.read(currentUserProfileProvider).value?.uid ??
        ref.read(authStateChangesProvider).value?.uid ??
        ref.read(authRepositoryProvider).currentUser?.uid;
    if (myUid == null) return;

    if (_isPendingRecipient(myUid)) {
      if (mounted) {
        AppSnackBar.warning(
          context,
          'Aceite a solicitacao para responder esta conversa.',
        );
      }
      return;
    }

    final otherUid = _resolveOtherUid(myUid);
    if (otherUid.isEmpty) {
      if (mounted) {
        AppSnackBar.error(context, 'Participantes da conversa invalidos.');
      }
      return;
    }

    if (!await _canSendMessageWithVerifiedEmail()) return;

    // Client-side throttle: block rapid-fire taps after all guards pass.
    final now = DateTime.now();
    if (_lastSendAttemptAt != null &&
        now.difference(_lastSendAttemptAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastSendAttemptAt = now;

    final previousRequestStatus = _currentRequestStatus;
    final previousRequestCycle = _currentRequestCycle;
    final previousRequestSenderId = _currentRequestSenderId;
    final replyToMessage = _replyingToMessage;
    final localMessageId = _addPendingMessage(
      text,
      replyToMessage: replyToMessage,
    );

    // Optimistic UX: clear instantly and send in background.
    _textController.clear();
    if (mounted) {
      setState(() {
        _replyingToMessage = null;
      });
    } else {
      _replyingToMessage = null;
    }
    _scrollToLatestMessage();

    unawaited(
      _sendMessageInBackground(
        localMessageId: localMessageId,
        text: text,
        myUid: myUid,
        otherUid: otherUid,
        previousRequestStatus: previousRequestStatus,
        previousRequestCycle: previousRequestCycle,
        previousRequestSenderId: previousRequestSenderId,
        replyToMessage: replyToMessage,
      ),
    );
  }

  Future<void> _sendMessageInBackground({
    required String localMessageId,
    required String text,
    required String myUid,
    required String otherUid,
    required String previousRequestStatus,
    required int previousRequestCycle,
    required String? previousRequestSenderId,
    required Message? replyToMessage,
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
          replyToMessageId: replyToMessage?.id,
          replyToSenderId: replyToMessage?.senderId,
          replyToText: replyToMessage?.text,
          replyToType: replyToMessage?.type,
          conversationType: _conversationType,
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
        await _maybeShowPendingRequestSnackbarAfterSend(
          repository: repository,
          myUid: myUid,
          previousRequestStatus: previousRequestStatus,
          previousRequestCycle: previousRequestCycle,
          previousRequestSenderId: previousRequestSenderId,
        );
        return;
      }

      _removePendingMessage(localMessageId);
      _restoreDraftIfInputEmpty(text, replyToMessage: replyToMessage);
      AppSnackBar.error(context, 'Erro ao enviar mensagem: $failureMessage');
    } catch (e) {
      if (!mounted) return;

      _removePendingMessage(localMessageId);
      _restoreDraftIfInputEmpty(text, replyToMessage: replyToMessage);

      AppSnackBar.error(context, 'Erro ao enviar mensagem: $e');
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
    final authAsync = ref.watch(authStateChangesProvider);
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;
    final authUser =
        authAsync.value ?? ref.read(authRepositoryProvider).currentUser;
    final currentUserId = user?.uid ?? authUser?.uid;

    if (currentUserId == null) {
      if (userAsync.isLoading || authAsync.isLoading) {
        return _buildInitialLoadingScaffold();
      }
      return const Scaffold(
        body: Center(child: Text('Usuario nao autenticado')),
      );
    }

    if (_accessState == _ConversationAccessState.checking &&
        !_isPreparingConversation) {
      unawaited(_prepareConversation());
    }

    final conversationAsync = _canReadConversation
        ? ref.watch(conversationStreamProvider(widget.conversationId))
        : null;
    final conversationExistsFromStream =
        conversationAsync?.value?.exists ?? false;
    final conversationExists =
        _hasPersistedConversation || conversationExistsFromStream;

    final messagesSnapshotAsync = _canReadConversation && conversationExists
        ? ref.watch(conversationMessagesSnapshotProvider(widget.conversationId))
        : null;

    if (conversationExists && !_conversationExists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _conversationExists) return;
        setState(() {
          _conversationExists = true;
        });
        _startRealtimeReadReceiptListener(
          currentUserId,
          ref.read(chatRepositoryProvider),
        );
      });
    }

    final conversationData = conversationAsync?.value?.data();
    final conversationMap = conversationData is Map<String, dynamic>
        ? conversationData
        : null;
    _syncConversationRequestState(conversationMap);
    final isPendingRecipient = _isPendingRecipient(currentUserId);

    final participants = List<String>.from(
      conversationMap?['participants'] ?? const <String>[],
    );

    final otherUid = participants.firstWhere(
      (uid) => uid != currentUserId,
      orElse: () => _resolveOtherUid(currentUserId),
    );

    final readUntilRaw = conversationMap?['readUntil'];
    final readUntilMap = readUntilRaw is Map
        ? Map<String, dynamic>.from(readUntilRaw)
        : const <String, dynamic>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: _buildAppBarTitle(), showBackButton: true),
      body: _buildChatBody(
        conversationExists: conversationExists,
        messagesSnapshotAsync: messagesSnapshotAsync,
        currentUserId: currentUserId,
        otherUid: otherUid,
        readUntilMap: readUntilMap,
        isPendingRecipient: isPendingRecipient,
      ),
    );
  }
}
