import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/typedefs.dart';
import '../domain/conversation_preview.dart';
import '../domain/message.dart';

/// Repository para gerenciar conversas e mensagens no Firestore.
class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  /// Calcula conversationId determinístico (uidMenor_uidMaior).
  String getConversationId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  /// Cria ou retorna conversa existente entre 2 usuários.
  ///
  /// Usa Transaction para idempotência (race condition safe).
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

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(conversationRef);

        if (!snapshot.exists) {
          // Criar nova conversa
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
          });

          // Criar previews para ambos os usuários
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
          });
        }
      });

      return Right(conversationId);
    } catch (e) {
      debugPrint('[Chat] Error creating conversation: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Envia mensagem de texto e atualiza metadata/previews atomicamente.
  FutureResult<Unit> sendMessage({
    required String conversationId,
    required String text,
    required String myUid,
    required String otherUid,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Nova mensagem
      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(); // Auto-gera ID

      batch.set(messageRef, {
        'senderId': myUid,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // 2. Metadata da conversa
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      batch.update(conversationRef, {
        'lastMessageText': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': myUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Preview do remetente (eu) - zera unread
      final myPreviewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      batch.update(myPreviewRef, {
        'lastMessageText': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': myUid,
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Preview do destinatário (outro) - incrementa unread
      final otherPreviewRef = _firestore
          .collection('users')
          .doc(otherUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      batch.update(otherPreviewRef, {
        'lastMessageText': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': myUid,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      debugPrint('[Chat] Error sending message: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Marca conversa como lida (zera unread, atualiza readUntil).
  FutureResult<Unit> markAsRead({
    required String conversationId,
    required String myUid,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Atualizar readUntil na conversa
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      batch.update(conversationRef, {
        'readUntil.$myUid': FieldValue.serverTimestamp(),
      });

      // 2. Zerar unreadCount no preview
      final myPreviewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      batch.update(myPreviewRef, {'unreadCount': 0});

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      debugPrint('[Chat] Error marking as read: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Stream de mensagens de uma conversa (últimas 50).
  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  /// Stream de previews de conversas do usuário (últimas 100).
  Stream<List<ConversationPreview>> getUserConversations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('conversationPreviews')
        .orderBy('lastMessageAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ConversationPreview.fromFirestore(doc))
              .toList(),
        );
  }

  /// Obtém document snapshot da conversa (para acessar readUntil).
  Future<DocumentSnapshot?> getConversationDoc(String conversationId) async {
    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
    if (!doc.exists) return null;
    return doc;
  }

  /// Stream do documento da conversa (para atualizações em tempo real de readUntil).
  Stream<DocumentSnapshot> getConversationStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots();
  }

  /// Deleta a conversa e os previews dos usuários.
  /// (As mensagens permanecem na subcollection, mas inacessíveis pelo app)
  FutureResult<Unit> deleteConversation({
    required String conversationId,
    required String myUid,
    required String otherUid,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Deletar preview do usuário atual
      final myPreviewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);
      batch.delete(myPreviewRef);

      // 2. Deletar preview do outro usuário (Opcional: Se for Unmatch, ambos somem?)
      // Se for apenas "apagar conversa", só o meu some.
      // Se for "Unmatch", ambos somem.
      // Vou assumir que deleteConversation apaga para AMBOS se passado both UIDs.
      final otherPreviewRef = _firestore
          .collection('users')
          .doc(otherUid)
          .collection('conversationPreviews')
          .doc(conversationId);
      batch.delete(otherPreviewRef);

      // 3. Deletar metadados da conversa (Doc pai)
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      batch.delete(conversationRef);

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      debugPrint('[Chat] Error deleting conversation: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

/// Provider para ChatRepository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});
