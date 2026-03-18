import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/errors/failure_mapper.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:mube/src/utils/app_performance_tracker.dart';

import '../domain/conversation_preview.dart';
import '../domain/message.dart';
import 'chat_access_resolver.dart';

/// Repository para gerenciar conversas e mensagens no Firestore.
class ChatRepository {
  final FirebaseFirestore _firestore;
  final AnalyticsService? _analytics;
  final AuthRepository? _authRepository;
  final ChatAccessResolver _chatAccessResolver;
  static const int _defaultMessagesPageSize = 50;
  static const Duration _securityContextRefreshCooldown = Duration(seconds: 4);
  static const String _requestStatusAccepted = 'accepted';
  static const String _requestStatusPending = 'pending';
  static const String _requestStatusRejected = 'rejected';
  DateTime? _lastSecurityContextRefreshAt;

  ChatRepository(
    this._firestore, {
    AnalyticsService? analytics,
    AuthRepository? authRepository,
    ChatAccessResolver? chatAccessResolver,
  }) : _analytics = analytics,
       _authRepository = authRepository,
       _chatAccessResolver =
           chatAccessResolver ?? ChatAccessResolver(_firestore);

  Failure _mapFailure(Object error, StackTrace stackTrace) =>
      mapExceptionToFailure(error, stackTrace);

  Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  String? _readNonEmptyString(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _firstNonEmptyString(
    List<Object?> values, {
    required String fallback,
  }) {
    for (final value in values) {
      final normalized = _readNonEmptyString(value);
      if (normalized != null) return normalized;
    }
    return fallback;
  }

  String _conversationTypeFromData(
    Map<String, dynamic>? data, {
    String fallback = 'direct',
  }) {
    return _readNonEmptyString(data?['type']) ?? fallback;
  }

  String _normalizeConversationType(
    String? type, {
    String fallback = 'direct',
  }) {
    return _readNonEmptyString(type) ?? fallback;
  }

  String _requestStatusFromData(
    Map<String, dynamic>? data, {
    String fallback = _requestStatusAccepted,
  }) {
    final normalized = _readNonEmptyString(data?['requestStatus']);
    if (normalized == _requestStatusPending ||
        normalized == _requestStatusRejected ||
        normalized == _requestStatusAccepted) {
      return normalized!;
    }
    return fallback;
  }

  int _requestCycleFromData(Map<String, dynamic>? data) {
    final value = data?['requestCycle'];
    if (value is num) return value.toInt();
    return 0;
  }

  String? _requestSenderIdFromData(Map<String, dynamic>? data) {
    return _readNonEmptyString(data?['requestSenderId']);
  }

  String? _requestRecipientIdFromData(Map<String, dynamic>? data) {
    return _readNonEmptyString(data?['requestRecipientId']);
  }

  String? _buildShortPersonName(Object? rawName) {
    final normalized = _readNonEmptyString(rawName);
    if (normalized == null) return null;

    final parts = normalized.split(RegExp(r'\s+'));
    if (parts.length <= 2) return normalized;

    const connectors = {'de', 'da', 'do', 'dos', 'das', 'e'};
    final takeCount = connectors.contains(parts[1].toLowerCase()) ? 3 : 2;
    return parts.take(takeCount).join(' ');
  }

  String _displayNameFromUserData(Map<String, dynamic>? data) {
    final professionalData = _asMap(data?['profissional']);
    final bandData = _asMap(data?['banda']);
    final studioData = _asMap(data?['estudio']);
    final contractorData = _asMap(data?['contratante']);
    final profileType = _readNonEmptyString(data?['tipo_perfil']);

    switch (profileType) {
      case 'profissional':
        return _firstNonEmptyString([
          professionalData?['nomeArtistico'],
          data?['nome'],
        ], fallback: 'Profissional');
      case 'banda':
        return _firstNonEmptyString([
          bandData?['nomeBanda'],
          bandData?['nomeArtistico'],
          bandData?['nome'],
          data?['nome'],
        ], fallback: 'Banda');
      case 'estudio':
        return _firstNonEmptyString([
          studioData?['nomeEstudio'],
          studioData?['nomeArtistico'],
          studioData?['nome'],
          data?['nome'],
        ], fallback: 'Estudio');
      case 'contratante':
        return _firstNonEmptyString([
          contractorData?['nomeExibicao'],
          _buildShortPersonName(data?['nome']),
          data?['nome'],
        ], fallback: 'Contratante');
      default:
        return _firstNonEmptyString([
          professionalData?['nomeArtistico'],
          bandData?['nomeBanda'],
          studioData?['nomeEstudio'],
          data?['nome'],
        ], fallback: 'Usuario');
    }
  }

  String _normalizedErrorMessage(Object error) {
    if (error is FirebaseException) {
      return [
        error.plugin,
        error.code,
        error.message ?? '',
        error.toString(),
      ].join(' ').toLowerCase();
    }

    if (error is PlatformException) {
      return [
        error.code,
        error.message ?? '',
        error.details?.toString() ?? '',
        error.toString(),
      ].join(' ').toLowerCase();
    }

    return error.toString().toLowerCase();
  }

  bool _isSecurityContextFailure(Object error) {
    final normalized = _normalizedErrorMessage(error);
    return normalized.contains('permission-denied') ||
        normalized.contains('permission denied') ||
        normalized.contains('unauthenticated') ||
        normalized.contains('failed-precondition') ||
        normalized.contains('failed precondition') ||
        (normalized.contains('app check') &&
            normalized.contains('channel-error'));
  }

  Future<bool> _refreshSecurityContextForRetry(
    Object error,
    StackTrace stackTrace, {
    required String operationLabel,
  }) async {
    final authRepository = _authRepository;
    if (authRepository == null || !_isSecurityContextFailure(error)) {
      return false;
    }

    final now = DateTime.now();
    if (_lastSecurityContextRefreshAt != null &&
        now.difference(_lastSecurityContextRefreshAt!) <
            _securityContextRefreshCooldown) {
      AppLogger.warning(
        'Chat Firestore security retry skipped during cooldown: '
        '$operationLabel',
        error,
        stackTrace,
        false,
      );
      return false;
    }

    _lastSecurityContextRefreshAt = now;
    AppLogger.setCustomKey('chat_security_retry_operation', operationLabel);
    AppLogger.setCustomKey(
      'chat_security_retry_error_type',
      error.runtimeType.toString(),
    );
    AppLogger.warning(
      'Chat Firestore security context failure on $operationLabel. '
      'Atualizando sessao e tentando novamente.',
      error,
      stackTrace,
      false,
    );

    final refreshResult = await authRepository.refreshSecurityContext();
    return refreshResult.fold(
      (failure) {
        AppLogger.warning(
          'Chat Firestore security context refresh failed: '
          '$operationLabel (${failure.debugMessage ?? failure.runtimeType})',
          failure,
          stackTrace,
          false,
        );
        return false;
      },
      (_) {
        AppLogger.info(
          'Chat Firestore security context refresh succeeded for '
          '$operationLabel.',
        );
        return true;
      },
    );
  }

  Future<T> _runWithSecurityContextRecovery<T>(
    Future<T> Function() operation, {
    required String operationLabel,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      final didRefresh = await _refreshSecurityContextForRetry(
        error,
        stackTrace,
        operationLabel: operationLabel,
      );
      if (!didRefresh) rethrow;
      return operation();
    }
  }

  Future<void> _commitBatchWithSecurityContextRecovery(
    void Function(WriteBatch batch) buildBatch, {
    required String operationLabel,
  }) {
    // Firestore batches are single-use. Recreate them on each retry attempt.
    return _runWithSecurityContextRecovery(() async {
      final batch = _firestore.batch();
      buildBatch(batch);
      await batch.commit();
    }, operationLabel: operationLabel);
  }

  Stream<T> _watchWithSecurityContextRecovery<T>(
    Stream<T> Function() createStream, {
    required String operationLabel,
  }) async* {
    var hasRetriedAfterRefresh = false;

    while (true) {
      try {
        yield* createStream();
        return;
      } catch (error, stackTrace) {
        if (hasRetriedAfterRefresh) {
          rethrow;
        }

        final didRefresh = await _refreshSecurityContextForRetry(
          error,
          stackTrace,
          operationLabel: operationLabel,
        );
        if (!didRefresh) {
          rethrow;
        }

        hasRetriedAfterRefresh = true;
      }
    }
  }

  Future<_UserPreviewInfo> _getUserPreviewInfo(String uid) async {
    final snapshot = await _runWithSecurityContextRecovery(
      () => _firestore.collection('users').doc(uid).get(),
      operationLabel: 'load_user_preview',
    );
    final data = _asMap(snapshot.data());
    return _UserPreviewInfo(
      displayName: _displayNameFromUserData(data),
      photoUrl: _readNonEmptyString(data?['foto']),
    );
  }

  Future<_UserPreviewInfo> _getUserPreviewInfoSafe(String uid) async {
    try {
      return await _getUserPreviewInfo(uid);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Chat: failed to fetch user preview info for $uid',
        e,
        stackTrace,
      );
      return const _UserPreviewInfo(displayName: 'Usuario', photoUrl: null);
    }
  }

  bool _isPendingForUser(
    Map<String, dynamic>? conversationData,
    String userId,
  ) {
    return _requestStatusFromData(conversationData) == _requestStatusPending &&
        _requestRecipientIdFromData(conversationData) == userId;
  }

  int _resolvePendingRequestCycle({
    required Map<String, dynamic>? conversationData,
    required String senderId,
    required String recipientId,
  }) {
    final currentStatus = _requestStatusFromData(conversationData);
    final currentCycle = _requestCycleFromData(conversationData);
    final currentSenderId = _requestSenderIdFromData(conversationData);
    final currentRecipientId = _requestRecipientIdFromData(conversationData);

    if (currentStatus == _requestStatusPending &&
        currentSenderId == senderId &&
        currentRecipientId == recipientId) {
      return currentCycle > 0 ? currentCycle : 1;
    }

    return currentCycle > 0 ? currentCycle + 1 : 1;
  }

  Map<String, dynamic> _buildAcceptedRequestFields({
    required Map<String, dynamic>? conversationData,
  }) {
    return {
      'requestStatus': _requestStatusAccepted,
      'requestRecipientId': null,
      'requestSenderId': null,
      'requestCycle': _requestCycleFromData(conversationData),
      'requestUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildPendingRequestFields({
    required Map<String, dynamic>? conversationData,
    required String senderId,
    required String recipientId,
  }) {
    return {
      'requestStatus': _requestStatusPending,
      'requestRecipientId': recipientId,
      'requestSenderId': senderId,
      'requestCycle': _resolvePendingRequestCycle(
        conversationData: conversationData,
        senderId: senderId,
        recipientId: recipientId,
      ),
      'requestUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildRejectedRequestFields({
    required Map<String, dynamic>? conversationData,
    required String senderId,
    required String recipientId,
  }) {
    return {
      'requestStatus': _requestStatusRejected,
      'requestRecipientId': recipientId,
      'requestSenderId': senderId,
      'requestCycle': _requestCycleFromData(conversationData),
      'requestUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildPreviewPayload({
    required String otherUserId,
    required String otherUserName,
    required String? otherUserPhoto,
    required String? lastMessageText,
    required Object? lastMessageAt,
    required String? lastSenderId,
    required Object unreadCount,
    required String type,
    required bool isPending,
    int? requestCycle,
  }) {
    return {
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhoto': otherUserPhoto,
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt,
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
      'updatedAt': FieldValue.serverTimestamp(),
      'type': type,
      'isPending': isPending,
      'requestCycle': requestCycle,
    };
  }

  Future<ChatParticipantPreview> getConversationParticipantPreview(
    String uid,
  ) async {
    final info = await _getUserPreviewInfoSafe(uid);
    return ChatParticipantPreview(
      displayName: info.displayName,
      photoUrl: info.photoUrl,
    );
  }

  Future<bool> _ensureConversationExistsForSend({
    required String conversationId,
    required String myUid,
    required String otherUid,
    required _UserPreviewInfo myInfo,
    required _UserPreviewInfo otherInfo,
    required String conversationType,
    required Map<String, dynamic> requestFields,
  }) async {
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final myPreviewRef = _firestore
        .collection('users')
        .doc(myUid)
        .collection('conversationPreviews')
        .doc(conversationId);
    final otherPreviewRef = _firestore
        .collection('users')
        .doc(otherUid)
        .collection('conversationPreviews')
        .doc(conversationId);

    final requestStatus =
        requestFields['requestStatus'] as String? ?? _requestStatusAccepted;
    final pendingCycle = requestFields['requestCycle'] is int
        ? requestFields['requestCycle'] as int
        : null;
    final senderPreviewCycle = requestStatus == _requestStatusPending
        ? pendingCycle
        : null;
    final recipientPreviewCycle = requestStatus == _requestStatusPending
        ? pendingCycle
        : null;
    final isRecipientPending = requestStatus == _requestStatusPending;

    var created = false;

    await _runWithSecurityContextRecovery(() {
      return _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(conversationRef);
        if (snapshot.exists) return;

        created = true;

        transaction.set(conversationRef, {
          'participants': [myUid, otherUid],
          'participantsMap': {myUid: true, otherUid: true},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'readUntil': {myUid: Timestamp(0, 0), otherUid: Timestamp(0, 0)},
          'lastMessageText': null,
          'lastMessageAt': null,
          'lastSenderId': null,
          'type': conversationType,
          ...requestFields,
        });

        transaction.set(
          myPreviewRef,
          _buildPreviewPayload(
            otherUserId: otherUid,
            otherUserName: otherInfo.displayName,
            otherUserPhoto: otherInfo.photoUrl,
            lastMessageText: null,
            lastMessageAt: null,
            lastSenderId: null,
            unreadCount: 0,
            type: conversationType,
            isPending: false,
            requestCycle: senderPreviewCycle,
          ),
        );

        transaction.set(
          otherPreviewRef,
          _buildPreviewPayload(
            otherUserId: myUid,
            otherUserName: myInfo.displayName,
            otherUserPhoto: myInfo.photoUrl,
            lastMessageText: null,
            lastMessageAt: null,
            lastSenderId: null,
            unreadCount: 0,
            type: conversationType,
            isPending: isRecipientPending,
            requestCycle: recipientPreviewCycle,
          ),
        );
      });
    }, operationLabel: 'send_message_prepare_conversation');

    return created;
  }

  /// Calcula conversationId deterministico (uidMenor_uidMaior).
  String getConversationId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  /// Cria ou retorna conversa existente entre 2 usuarios.
  ///
  /// Usa Transaction para idempotencia (race condition safe).
  FutureResult<String> getOrCreateConversation({
    required String myUid,
    required String otherUid,
    required String otherUserName,
    String? otherUserPhoto,
    required String myName,
    String? myPhoto,
    String type = 'direct',
  }) async {
    try {
      final conversationId = getConversationId(myUid, otherUid);
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      var hasCreatedConversation = false;

      await _runWithSecurityContextRecovery(() {
        return _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(conversationRef);

          final myPreviewRef = _firestore
              .collection('users')
              .doc(myUid)
              .collection('conversationPreviews')
              .doc(conversationId);

          final otherPreviewRef = _firestore
              .collection('users')
              .doc(otherUid)
              .collection('conversationPreviews')
              .doc(conversationId);

          final conversationData = _asMap(snapshot.data());
          final conversationType = _conversationTypeFromData(
            conversationData,
            fallback: type,
          );
          hasCreatedConversation = !snapshot.exists;

          if (!snapshot.exists) {
            transaction.set(conversationRef, {
              'participants': [myUid, otherUid],
              'participantsMap': {myUid: true, otherUid: true},
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'readUntil': {myUid: Timestamp(0, 0), otherUid: Timestamp(0, 0)},
              'lastMessageText': null,
              'lastMessageAt': null,
              'lastSenderId': null,
              'type': type,
              'requestStatus': _requestStatusAccepted,
              'requestRecipientId': null,
              'requestSenderId': null,
              'requestCycle': 0,
              'requestUpdatedAt': FieldValue.serverTimestamp(),
            });

            transaction.set(myPreviewRef, {
              'otherUserId': otherUid,
              'otherUserName': otherUserName,
              'otherUserPhoto': otherUserPhoto,
              'lastMessageText': null,
              'lastMessageAt': null,
              'lastSenderId': null,
              'unreadCount': 0,
              'updatedAt': FieldValue.serverTimestamp(),
              'type': type,
              'isPending': false,
              'requestCycle': null,
            });

            transaction.set(otherPreviewRef, {
              'otherUserId': myUid,
              'otherUserName': myName,
              'otherUserPhoto': myPhoto,
              'lastMessageText': null,
              'lastMessageAt': null,
              'lastSenderId': null,
              'unreadCount': 0,
              'updatedAt': FieldValue.serverTimestamp(),
              'type': type,
              'isPending': false,
              'requestCycle': null,
            });
          } else {
            transaction.set(myPreviewRef, {
              'otherUserId': otherUid,
              'otherUserName': otherUserName,
              'otherUserPhoto': otherUserPhoto,
              'lastMessageText': conversationData?['lastMessageText'],
              'lastMessageAt': conversationData?['lastMessageAt'],
              'lastSenderId': conversationData?['lastSenderId'],
              'updatedAt': FieldValue.serverTimestamp(),
              'type': conversationType,
              'isPending': _isPendingForUser(conversationData, myUid),
              'requestCycle': _isPendingForUser(conversationData, myUid)
                  ? _requestCycleFromData(conversationData)
                  : null,
            }, SetOptions(merge: true));
            transaction.set(otherPreviewRef, {
              'otherUserId': myUid,
              'otherUserName': myName,
              'otherUserPhoto': myPhoto,
              'lastMessageText': conversationData?['lastMessageText'],
              'lastMessageAt': conversationData?['lastMessageAt'],
              'lastSenderId': conversationData?['lastSenderId'],
              'updatedAt': FieldValue.serverTimestamp(),
              'type': conversationType,
              'isPending': _isPendingForUser(conversationData, otherUid),
              'requestCycle': _isPendingForUser(conversationData, otherUid)
                  ? _requestCycleFromData(conversationData)
                  : null,
            }, SetOptions(merge: true));
          }
        });
      }, operationLabel: 'get_or_create_conversation');

      if (hasCreatedConversation) {
        await _analytics?.logEvent(
          name: 'chat_initiated',
          parameters: {
            'conversation_id': conversationId,
            'other_user_id': otherUid,
            'source': type,
          },
        );
      }

      return Right(conversationId);
    } catch (e, stackTrace) {
      AppLogger.error('Chat: failed to create conversation', e, stackTrace);
      return Left(_mapFailure(e, stackTrace));
    }
  }

  /// Envia mensagem de texto e atualiza metadata/previews atomicamente.
  FutureResult<Unit> sendMessage({
    required String conversationId,
    required String text,
    required String myUid,
    required String otherUid,
    String? clientMessageId,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToText,
    String? replyToType,
    String conversationType = 'direct',
  }) async {
    try {
      final normalizedText = text.trim();

      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      final myInfoFuture = _getUserPreviewInfoSafe(myUid);
      final otherInfoFuture = _getUserPreviewInfoSafe(otherUid);
      var hasCreatedConversation = false;

      final conversationSnapshot = await _runWithSecurityContextRecovery(
        () => conversationRef.get(),
        operationLabel: 'send_message_load_conversation',
      );
      final myInfo = await myInfoFuture;
      final otherInfo = await otherInfoFuture;
      final conversationData = _asMap(conversationSnapshot.data());
      final requestedConversationType = _normalizeConversationType(
        conversationType,
      );

      if (!conversationSnapshot.exists) {
        hasCreatedConversation = true;
      }

      final resolvedConversationType = _conversationTypeFromData(
        conversationData,
        fallback: requestedConversationType,
      );
      final currentRequestStatus = _requestStatusFromData(conversationData);
      final pendingSenderId = _requestSenderIdFromData(conversationData);
      final pendingRecipientId = _requestRecipientIdFromData(conversationData);

      late Map<String, dynamic> requestFields;
      if (!conversationSnapshot.exists ||
          currentRequestStatus == _requestStatusRejected) {
        final deliveryDecision = await _chatAccessResolver.resolveDelivery(
          senderId: myUid,
          recipientId: otherUid,
        );
        requestFields = deliveryDecision.isAccepted
            ? _buildAcceptedRequestFields(conversationData: conversationData)
            : _buildPendingRequestFields(
                conversationData: conversationData,
                senderId: myUid,
                recipientId: otherUid,
              );
      } else if (currentRequestStatus == _requestStatusPending &&
          pendingSenderId != null &&
          pendingRecipientId != null) {
        final pendingDecision = await _chatAccessResolver.resolveDelivery(
          senderId: pendingSenderId,
          recipientId: pendingRecipientId,
        );

        if (myUid == pendingRecipientId && pendingDecision.isPending) {
          return const Left(
            PermissionFailure(
              message:
                  'Aceite a solicitação antes de responder para continuar nesta conversa.',
              debugMessage: 'chat-request-awaiting-accept',
            ),
          );
        }

        requestFields = pendingDecision.isAccepted
            ? _buildAcceptedRequestFields(conversationData: conversationData)
            : _buildPendingRequestFields(
                conversationData: conversationData,
                senderId: pendingSenderId,
                recipientId: pendingRecipientId,
              );
      } else {
        requestFields = _buildAcceptedRequestFields(
          conversationData: conversationData,
        );
      }

      final requestStatus =
          requestFields['requestStatus'] as String? ?? _requestStatusAccepted;
      final pendingCycle = requestFields['requestCycle'] is int
          ? requestFields['requestCycle'] as int
          : null;
      final senderPreviewCycle = requestStatus == _requestStatusPending
          ? pendingCycle
          : null;
      final recipientPreviewCycle = requestStatus == _requestStatusPending
          ? pendingCycle
          : null;
      final isRecipientPending = requestStatus == _requestStatusPending;

      if (!conversationSnapshot.exists) {
        hasCreatedConversation = await _ensureConversationExistsForSend(
          conversationId: conversationId,
          myUid: myUid,
          otherUid: otherUid,
          myInfo: myInfo,
          otherInfo: otherInfo,
          conversationType: resolvedConversationType,
          requestFields: requestFields,
        );
      }

      final messageRef = conversationRef.collection('messages').doc();
      final messageData = <String, dynamic>{
        'senderId': myUid,
        'text': normalizedText,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'text',
        'sender_name': myInfo.displayName,
        'sender_photo': myInfo.photoUrl,
      };
      if (clientMessageId != null) {
        messageData['clientMessageId'] = clientMessageId;
      }
      if (replyToMessageId != null) {
        messageData['replyToMessageId'] = replyToMessageId;
      }
      if (replyToSenderId != null) {
        messageData['replyToSenderId'] = replyToSenderId;
      }
      if (replyToText != null) {
        messageData['replyToText'] = replyToText;
      }
      if (replyToType != null) {
        messageData['replyToType'] = replyToType;
      }

      final myPreviewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      final otherPreviewRef = _firestore
          .collection('users')
          .doc(otherUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      await _commitBatchWithSecurityContextRecovery((batch) {
        batch.set(messageRef, messageData);

        batch.set(conversationRef, {
          'lastMessageText': normalizedText,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': myUid,
          'updatedAt': FieldValue.serverTimestamp(),
          'type': resolvedConversationType,
          ...requestFields,
        }, SetOptions(merge: true));

        batch.set(
          myPreviewRef,
          _buildPreviewPayload(
            otherUserId: otherUid,
            otherUserName: otherInfo.displayName,
            otherUserPhoto: otherInfo.photoUrl,
            lastMessageText: normalizedText,
            lastMessageAt: FieldValue.serverTimestamp(),
            lastSenderId: myUid,
            unreadCount: 0,
            type: resolvedConversationType,
            isPending: false,
            requestCycle: senderPreviewCycle,
          ),
          SetOptions(merge: true),
        );

        batch.set(
          otherPreviewRef,
          _buildPreviewPayload(
            otherUserId: myUid,
            otherUserName: myInfo.displayName,
            otherUserPhoto: myInfo.photoUrl,
            lastMessageText: normalizedText,
            lastMessageAt: FieldValue.serverTimestamp(),
            lastSenderId: myUid,
            unreadCount: FieldValue.increment(1),
            type: resolvedConversationType,
            isPending: isRecipientPending,
            requestCycle: recipientPreviewCycle,
          ),
          SetOptions(merge: true),
        );
      }, operationLabel: 'send_message_commit');

      if (hasCreatedConversation) {
        await _analytics?.logEvent(
          name: 'chat_initiated',
          parameters: {
            'conversation_id': conversationId,
            'other_user_id': otherUid,
            'source': resolvedConversationType,
          },
        );
      }

      await _analytics?.logEvent(
        name: 'message_sent',
        parameters: {'conversation_id': conversationId, 'has_media': false},
      );

      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error('Chat: failed to send message', e, stackTrace);
      final failure = _mapFailure(e, stackTrace);

      await _analytics?.logEvent(
        name: 'message_sent_error',
        parameters: {
          'conversation_id': conversationId,
          'error_type': failure.runtimeType.toString(),
          'error_code': failure.debugMessage ?? 'unknown',
        },
      );

      return Left(failure);
    }
  }

  /// Marca conversa como lida (zera unread, atualiza readUntil).
  FutureResult<Unit> markAsRead({
    required String conversationId,
    required String myUid,
  }) async {
    try {
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      final myPreviewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);
      await _commitBatchWithSecurityContextRecovery((batch) {
        batch.update(conversationRef, {
          'readUntil.$myUid': FieldValue.serverTimestamp(),
        });
        batch.set(myPreviewRef, {'unreadCount': 0}, SetOptions(merge: true));
      }, operationLabel: 'mark_as_read');
      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat: failed to mark conversation as read',
        e,
        stackTrace,
      );
      return Left(_mapFailure(e, stackTrace));
    }
  }

  Query<Map<String, dynamic>> _messagesQuery(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesSnapshot(
    String conversationId, {
    int limit = _defaultMessagesPageSize,
  }) async* {
    final query = _messagesQuery(conversationId).limit(limit);
    final firstSnapshotStopwatch = AppPerformanceTracker.startSpan(
      'chat.messages_stream.first_snapshot',
      data: {'conversation_id': conversationId, 'limit': limit},
    );
    final firstServerSnapshotStopwatch = AppPerformanceTracker.startSpan(
      'chat.messages_stream.first_server_snapshot',
      data: {'conversation_id': conversationId, 'limit': limit},
    );
    var hasFinishedFirstSnapshot = false;
    var hasFinishedFirstServerSnapshot = false;

    final cacheLookupStopwatch = AppPerformanceTracker.startSpan(
      'chat.messages_stream.cache_lookup',
      data: {'conversation_id': conversationId, 'limit': limit},
    );
    try {
      final cachedSnapshot = await query.get(
        const GetOptions(source: Source.cache),
      );
      final cachedDocsCount = cachedSnapshot.docs.length;
      AppPerformanceTracker.finishSpan(
        'chat.messages_stream.cache_lookup',
        cacheLookupStopwatch,
        data: {
          'conversation_id': conversationId,
          'status': cachedDocsCount > 0 ? 'hit' : 'empty',
          'size': cachedDocsCount,
        },
      );

      if (cachedDocsCount > 0) {
        AppPerformanceTracker.finishSpan(
          'chat.messages_stream.first_snapshot',
          firstSnapshotStopwatch,
          data: {
            'conversation_id': conversationId,
            'source': 'cache',
            'size': cachedDocsCount,
            'has_pending_writes': cachedSnapshot.metadata.hasPendingWrites,
          },
        );
        hasFinishedFirstSnapshot = true;
        yield cachedSnapshot;
      }
    } catch (_) {
      AppPerformanceTracker.finishSpan(
        'chat.messages_stream.cache_lookup',
        cacheLookupStopwatch,
        data: {'conversation_id': conversationId, 'status': 'error'},
      );
    }

    try {
      await for (final snapshot in _watchWithSecurityContextRecovery(
        () => query.snapshots(includeMetadataChanges: true),
        operationLabel: 'watch_messages_snapshot',
      )) {
        if (!hasFinishedFirstSnapshot) {
          AppPerformanceTracker.finishSpan(
            'chat.messages_stream.first_snapshot',
            firstSnapshotStopwatch,
            data: {
              'conversation_id': conversationId,
              'source': snapshot.metadata.isFromCache
                  ? 'stream_cache'
                  : 'server',
              'size': snapshot.docs.length,
              'has_pending_writes': snapshot.metadata.hasPendingWrites,
            },
          );
          hasFinishedFirstSnapshot = true;
        }

        if (!hasFinishedFirstServerSnapshot && !snapshot.metadata.isFromCache) {
          AppPerformanceTracker.finishSpan(
            'chat.messages_stream.first_server_snapshot',
            firstServerSnapshotStopwatch,
            data: {
              'conversation_id': conversationId,
              'size': snapshot.docs.length,
              'has_pending_writes': snapshot.metadata.hasPendingWrites,
            },
          );
          hasFinishedFirstServerSnapshot = true;
        }

        yield snapshot;
      }
    } finally {
      if (!hasFinishedFirstSnapshot) {
        AppPerformanceTracker.finishSpan(
          'chat.messages_stream.first_snapshot',
          firstSnapshotStopwatch,
          data: {
            'conversation_id': conversationId,
            'status': 'disposed_without_snapshot',
          },
        );
      }
      if (!hasFinishedFirstServerSnapshot) {
        AppPerformanceTracker.finishSpan(
          'chat.messages_stream.first_server_snapshot',
          firstServerSnapshotStopwatch,
          data: {
            'conversation_id': conversationId,
            'status': 'disposed_without_server',
          },
        );
      }
    }
  }

  /// Stream de mensagens de uma conversa (ultimas 50).
  Stream<List<Message>> getMessages(String conversationId) {
    return getMessagesSnapshot(conversationId).map(
      (snapshot) =>
          snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
    );
  }

  Future<MessagesPage> getMessagesPage({
    required String conversationId,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
    int limit = _defaultMessagesPageSize,
  }) async {
    var query = _messagesQuery(conversationId).limit(limit);
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snapshot = await _runWithSecurityContextRecovery(
      () => query.get(),
      operationLabel: 'get_messages_page',
    );
    final messages = snapshot.docs
        .map((doc) => Message.fromFirestore(doc))
        .toList(growable: false);
    final lastVisibleDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length >= limit;

    return MessagesPage(
      messages: messages,
      lastVisibleDoc: lastVisibleDoc,
      hasMore: hasMore,
    );
  }

  /// Stream de previews de conversas do usuario (ultimas 100).
  Stream<List<ConversationPreview>> getUserConversations(String userId) {
    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('conversationPreviews')
        .orderBy('lastMessageAt', descending: true)
        .limit(100);

    return (() async* {
      try {
        final cachedSnapshot = await query.get(
          const GetOptions(source: Source.cache),
        );
        if (cachedSnapshot.docs.isNotEmpty) {
          yield cachedSnapshot.docs
              .map((doc) => ConversationPreview.fromFirestore(doc))
              .toList(growable: false);
        }
      } catch (_) {
        // Best effort only. Live snapshots below remain the source of truth.
      }

      yield* _watchWithSecurityContextRecovery(
        () => query.snapshots(includeMetadataChanges: true),
        operationLabel: 'watch_user_conversations',
      ).map(
        (snapshot) => snapshot.docs
            .map((doc) => ConversationPreview.fromFirestore(doc))
            .toList(growable: false),
      );
    })();
  }

  Stream<List<ConversationPreview>> getUserAcceptedConversations(
    String userId,
  ) {
    return getUserConversations(
      userId,
    ).map((items) => items.where((item) => !item.isPending).toList());
  }

  Stream<List<ConversationPreview>> getUserPendingConversations(String userId) {
    return getUserConversations(
      userId,
    ).map((items) => items.where((item) => item.isPending).toList());
  }

  /// Obtem document snapshot da conversa (para acessar readUntil).
  Future<DocumentSnapshot?> getConversationDoc(String conversationId) async {
    final doc = await _runWithSecurityContextRecovery(
      () => _firestore.collection('conversations').doc(conversationId).get(),
      operationLabel: 'get_conversation_doc',
    );
    if (!doc.exists) return null;
    return doc;
  }

  /// Stream do documento da conversa (para atualizacoes em tempo real de readUntil).
  Stream<DocumentSnapshot> getConversationStream(String conversationId) {
    return _watchWithSecurityContextRecovery(
      () => _firestore
          .collection('conversations')
          .doc(conversationId)
          .snapshots(),
      operationLabel: 'watch_conversation_doc',
    );
  }

  /// Restaura o preview do usuario atual sem apagar o historico da conversa.
  FutureResult<Unit> restoreConversationPreview({
    required String conversationId,
    required String myUid,
    required String otherUid,
    String? fallbackOtherUserName,
    String? fallbackOtherUserPhoto,
  }) async {
    try {
      final previewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      final conversationSnapshot = await _runWithSecurityContextRecovery(
        () => conversationRef.get(),
        operationLabel: 'restore_conversation_preview_load_conversation',
      );
      final conversationData = _asMap(conversationSnapshot.data());
      final conversationType = _conversationTypeFromData(conversationData);

      var otherUserName = _readNonEmptyString(fallbackOtherUserName);
      var otherUserPhoto = _readNonEmptyString(fallbackOtherUserPhoto);

      if (otherUserName == null || otherUserPhoto == null) {
        final otherInfo = await _getUserPreviewInfo(otherUid);
        otherUserName ??= otherInfo.displayName;
        otherUserPhoto ??= otherInfo.photoUrl;
      }

      await _runWithSecurityContextRecovery(() {
        return previewRef.set({
          'otherUserId': otherUid,
          'otherUserName': otherUserName,
          'otherUserPhoto': otherUserPhoto,
          'lastMessageText': conversationData?['lastMessageText'],
          'lastMessageAt': conversationData?['lastMessageAt'],
          'lastSenderId': conversationData?['lastSenderId'],
          'unreadCount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'type': conversationType,
          'isPending': _isPendingForUser(conversationData, myUid),
          'requestCycle': _isPendingForUser(conversationData, myUid)
              ? _requestCycleFromData(conversationData)
              : null,
        }, SetOptions(merge: true));
      }, operationLabel: 'restore_conversation_preview_commit');

      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat: failed to restore conversation preview',
        e,
        stackTrace,
      );
      return Left(_mapFailure(e, stackTrace));
    }
  }

  /// Oculta a conversa para o usuario atual removendo apenas seu preview.
  /// Mantem conversa e preview do outro usuario para respeitar as rules.
  FutureResult<Unit> deleteConversation({
    required String conversationId,
    required String myUid,
    required String otherUid,
  }) async {
    try {
      final myPreviewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);
      await _commitBatchWithSecurityContextRecovery((batch) {
        batch.delete(myPreviewRef);
      }, operationLabel: 'delete_conversation_preview');

      await _analytics?.logEvent(
        name: 'conversation_deleted',
        parameters: {
          'conversation_id': conversationId,
          'other_user_id': otherUid,
        },
      );

      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat: failed to delete conversation preview',
        e,
        stackTrace,
      );
      return Left(_mapFailure(e, stackTrace));
    }
  }

  FutureResult<Unit> acceptConversationRequest({
    required String conversationId,
    required String myUid,
    required String otherUid,
  }) async {
    try {
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      final myPreviewRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);
      final otherPreviewRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(otherUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      final conversationSnapshot = await _runWithSecurityContextRecovery(
        () => conversationRef.get(),
        operationLabel: 'accept_conversation_request_load_conversation',
      );
      final conversationData = _asMap(conversationSnapshot.data());

      await _commitBatchWithSecurityContextRecovery((batch) {
        batch.set(
          conversationRef,
          _buildAcceptedRequestFields(conversationData: conversationData),
          SetOptions(merge: true),
        );
        batch.set(myPreviewRef, {
          'isPending': false,
          'requestCycle': null,
        }, SetOptions(merge: true));
        batch.set(otherPreviewRef, {
          'isPending': false,
          'requestCycle': null,
        }, SetOptions(merge: true));
      }, operationLabel: 'accept_conversation_request_commit');
      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat: failed to accept conversation request',
        e,
        stackTrace,
      );
      return Left(_mapFailure(e, stackTrace));
    }
  }

  FutureResult<Unit> rejectConversationRequest({
    required String conversationId,
    required String myUid,
    required String otherUid,
  }) async {
    try {
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      final senderPreviewRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(otherUid)
          .collection('conversationPreviews')
          .doc(conversationId);
      final recipientPreviewRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      final conversationSnapshot = await _runWithSecurityContextRecovery(
        () => conversationRef.get(),
        operationLabel: 'reject_conversation_request_load_conversation',
      );
      final conversationData = _asMap(conversationSnapshot.data());
      final requestSenderId =
          _requestSenderIdFromData(conversationData) ?? otherUid;
      final requestRecipientId =
          _requestRecipientIdFromData(conversationData) ?? myUid;

      await _commitBatchWithSecurityContextRecovery((batch) {
        batch.set(
          conversationRef,
          _buildRejectedRequestFields(
            conversationData: conversationData,
            senderId: requestSenderId,
            recipientId: requestRecipientId,
          ),
          SetOptions(merge: true),
        );
        batch.set(senderPreviewRef, {
          'isPending': false,
          'requestCycle': null,
        }, SetOptions(merge: true));
        batch.delete(recipientPreviewRef);
      }, operationLabel: 'reject_conversation_request_commit');
      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat: failed to reject conversation request',
        e,
        stackTrace,
      );
      return Left(_mapFailure(e, stackTrace));
    }
  }

  FutureResult<Unit> reevaluateConversationAccess({
    required String conversationId,
    String trigger = 'manual',
  }) async {
    try {
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      final snapshot = await _runWithSecurityContextRecovery(
        () => conversationRef.get(),
        operationLabel: 'reevaluate_conversation_access_load_conversation',
      );
      if (!snapshot.exists) return const Right(unit);

      final conversationData = _asMap(snapshot.data());
      if (_requestStatusFromData(conversationData) != _requestStatusPending) {
        return const Right(unit);
      }

      final requestSenderId = _requestSenderIdFromData(conversationData);
      final requestRecipientId = _requestRecipientIdFromData(conversationData);
      if (requestSenderId == null || requestRecipientId == null) {
        return const Right(unit);
      }

      final decision = await _chatAccessResolver.resolveDelivery(
        senderId: requestSenderId,
        recipientId: requestRecipientId,
      );
      if (decision.isPending) return const Right(unit);

      final senderPreviewRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(requestSenderId)
          .collection('conversationPreviews')
          .doc(conversationId);
      final recipientPreviewRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(requestRecipientId)
          .collection('conversationPreviews')
          .doc(conversationId);

      await _commitBatchWithSecurityContextRecovery((batch) {
        batch.set(
          conversationRef,
          _buildAcceptedRequestFields(conversationData: conversationData),
          SetOptions(merge: true),
        );
        batch.set(senderPreviewRef, {
          'isPending': false,
          'requestCycle': null,
        }, SetOptions(merge: true));
        batch.set(recipientPreviewRef, {
          'isPending': false,
          'requestCycle': null,
        }, SetOptions(merge: true));
      }, operationLabel: 'reevaluate_conversation_access_commit');

      await _analytics?.logEvent(
        name: 'chat_request_promoted',
        parameters: {
          'conversation_id': conversationId,
          'trigger': trigger,
          'reason': decision.reason.name,
        },
      );

      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat: failed to reevaluate conversation access',
        e,
        stackTrace,
      );
      return Left(_mapFailure(e, stackTrace));
    }
  }

  FutureResult<Unit> reevaluateConversationAccessByUsers({
    required String userAId,
    required String userBId,
    String trigger = 'manual',
  }) {
    return reevaluateConversationAccess(
      conversationId: getConversationId(userAId, userBId),
      trigger: trigger,
    );
  }

  FutureResult<Unit> reevaluatePendingConversationsForRecipient({
    required String recipientId,
    String trigger = 'manual',
  }) async {
    try {
      final snapshot = await _runWithSecurityContextRecovery(
        () => _firestore
            .collection(FirestoreCollections.users)
            .doc(recipientId)
            .collection('conversationPreviews')
            .where('isPending', isEqualTo: true)
            .get(),
        operationLabel: 'reevaluate_pending_conversations_for_recipient',
      );

      for (final previewDoc in snapshot.docs) {
        final result = await reevaluateConversationAccess(
          conversationId: previewDoc.id,
          trigger: trigger,
        );
        result.fold(
          (failure) => AppLogger.warning(
            'Falha ao reavaliar conversa pendente ${previewDoc.id}',
            failure.message,
          ),
          (_) {},
        );
      }

      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat: failed to reevaluate pending conversations for recipient',
        e,
        stackTrace,
      );
      return Left(_mapFailure(e, stackTrace));
    }
  }
}

class _UserPreviewInfo {
  const _UserPreviewInfo({required this.displayName, required this.photoUrl});

  final String displayName;
  final String? photoUrl;
}

class ChatParticipantPreview {
  const ChatParticipantPreview({
    required this.displayName,
    required this.photoUrl,
  });

  final String displayName;
  final String? photoUrl;
}

class MessagesPage {
  const MessagesPage({
    required this.messages,
    required this.lastVisibleDoc,
    required this.hasMore,
  });

  final List<Message> messages;
  final DocumentSnapshot<Map<String, dynamic>>? lastVisibleDoc;
  final bool hasMore;
}

/// Provider para ChatRepository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final analytics = ref.read(analyticsServiceProvider);
  return ChatRepository(
    ref.read(firebaseFirestoreProvider),
    analytics: analytics,
    authRepository: ref.read(authRepositoryProvider),
    chatAccessResolver: ref.read(chatAccessResolverProvider),
  );
});
