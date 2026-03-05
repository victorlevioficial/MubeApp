import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/utils/app_logger.dart';

import '../domain/conversation_preview.dart';
import '../domain/message.dart';

/// Repository para gerenciar conversas e mensagens no Firestore.
class ChatRepository {
  final FirebaseFirestore _firestore;
  final AnalyticsService? _analytics;
  static const int _defaultMessagesPageSize = 50;

  ChatRepository(this._firestore, {AnalyticsService? analytics})
    : _analytics = analytics;

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

  Future<_UserPreviewInfo> _getUserPreviewInfo(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
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

      await _firestore.runTransaction((transaction) async {
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
          }, SetOptions(merge: true));
        }
      });

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
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Envia mensagem de texto e atualiza metadata/previews atomicamente.
  FutureResult<Unit> sendMessage({
    required String conversationId,
    required String text,
    required String myUid,
    required String otherUid,
    String? clientMessageId,
  }) async {
    try {
      final normalizedText = text.trim();
      final batch = _firestore.batch();

      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      final conversationFuture = conversationRef.get();
      final myInfoFuture = _getUserPreviewInfoSafe(myUid);
      final otherInfoFuture = _getUserPreviewInfoSafe(otherUid);

      final conversationSnapshot = await conversationFuture;
      final myInfo = await myInfoFuture;
      final otherInfo = await otherInfoFuture;
      final conversationData = _asMap(conversationSnapshot.data());
      final conversationType = _conversationTypeFromData(conversationData);

      final messageRef = conversationRef.collection('messages').doc();
      final messageData = <String, dynamic>{
        'senderId': myUid,
        'text': normalizedText,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'text',
      };
      if (clientMessageId != null) {
        messageData['clientMessageId'] = clientMessageId;
      }
      batch.set(messageRef, messageData);

      batch.set(conversationRef, {
        'lastMessageText': normalizedText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': myUid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final myPreviewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      batch.set(myPreviewRef, {
        'otherUserId': otherUid,
        'otherUserName': otherInfo.displayName,
        'otherUserPhoto': otherInfo.photoUrl,
        'lastMessageText': normalizedText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': myUid,
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'type': conversationType,
      }, SetOptions(merge: true));

      final otherPreviewRef = _firestore
          .collection('users')
          .doc(otherUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      batch.set(otherPreviewRef, {
        'otherUserId': myUid,
        'otherUserName': myInfo.displayName,
        'otherUserPhoto': myInfo.photoUrl,
        'lastMessageText': normalizedText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': myUid,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
        'type': conversationType,
      }, SetOptions(merge: true));

      await batch.commit();

      await _analytics?.logEvent(
        name: 'message_sent',
        parameters: {'conversation_id': conversationId, 'has_media': false},
      );

      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error('Chat: failed to send message', e, stackTrace);

      await _analytics?.logEvent(
        name: 'message_sent_error',
        parameters: {
          'conversation_id': conversationId,
          'error_message': e.toString(),
        },
      );

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

      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      batch.update(conversationRef, {
        'readUntil.$myUid': FieldValue.serverTimestamp(),
      });

      final myPreviewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);

      batch.set(myPreviewRef, {'unreadCount': 0}, SetOptions(merge: true));

      await batch.commit();
      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat: failed to mark conversation as read',
        e,
        stackTrace,
      );
      return Left(ServerFailure(message: e.toString()));
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
  }) {
    return _messagesQuery(conversationId).limit(limit).snapshots();
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

    final snapshot = await query.get();
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

  /// Obtem document snapshot da conversa (para acessar readUntil).
  Future<DocumentSnapshot?> getConversationDoc(String conversationId) async {
    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
    if (!doc.exists) return null;
    return doc;
  }

  /// Stream do documento da conversa (para atualizacoes em tempo real de readUntil).
  Stream<DocumentSnapshot> getConversationStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots();
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

      final conversationSnapshot = await conversationRef.get();
      final conversationData = _asMap(conversationSnapshot.data());
      final conversationType = _conversationTypeFromData(conversationData);

      var otherUserName = _readNonEmptyString(fallbackOtherUserName);
      var otherUserPhoto = _readNonEmptyString(fallbackOtherUserPhoto);

      if (otherUserName == null || otherUserPhoto == null) {
        final otherInfo = await _getUserPreviewInfo(otherUid);
        otherUserName ??= otherInfo.displayName;
        otherUserPhoto ??= otherInfo.photoUrl;
      }

      await previewRef.set({
        'otherUserId': otherUid,
        'otherUserName': otherUserName,
        'otherUserPhoto': otherUserPhoto,
        'lastMessageText': conversationData?['lastMessageText'],
        'lastMessageAt': conversationData?['lastMessageAt'],
        'lastSenderId': conversationData?['lastSenderId'],
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'type': conversationType,
      }, SetOptions(merge: true));

      return const Right(unit);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat: failed to restore conversation preview',
        e,
        stackTrace,
      );
      return Left(ServerFailure(message: e.toString()));
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
      final batch = _firestore.batch();

      final myPreviewRef = _firestore
          .collection('users')
          .doc(myUid)
          .collection('conversationPreviews')
          .doc(conversationId);
      batch.delete(myPreviewRef);

      await batch.commit();

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
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

class _UserPreviewInfo {
  const _UserPreviewInfo({required this.displayName, required this.photoUrl});

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
  return ChatRepository(FirebaseFirestore.instance, analytics: analytics);
});
