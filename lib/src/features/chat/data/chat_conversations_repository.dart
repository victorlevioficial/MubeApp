part of 'chat_repository.dart';

mixin _ChatConversationsRepository on _ChatRepositoryBase {
  Future<ChatParticipantPreview> getConversationParticipantPreview(
    String uid,
  ) async {
    final info = await _getUserPreviewInfoSafe(uid);
    return ChatParticipantPreview(
      displayName: info.displayName,
      photoUrl: info.photoUrl,
    );
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
}
