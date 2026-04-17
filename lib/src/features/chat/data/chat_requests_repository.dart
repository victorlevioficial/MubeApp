part of 'chat_repository.dart';

mixin _ChatRequestsRepository on _ChatRepositoryBase {
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
        allowCached: false,
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
