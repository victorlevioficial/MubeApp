part of 'chat_repository.dart';

mixin _ChatMessagesRepository on _ChatRepositoryBase {
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
      (snapshot) => snapshot.docs
          .where(_isVisibleMessageDoc)
          .map((doc) => Message.fromFirestore(doc))
          .toList(),
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
        .where(_isVisibleMessageDoc)
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

  bool _isVisibleMessageDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return false;

    return data['hidden'] != true &&
        data['rate_limited'] != true &&
        data['moderation_state'] != 'rate_limited';
  }
}
