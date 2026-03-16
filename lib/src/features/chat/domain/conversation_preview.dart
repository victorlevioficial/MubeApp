import 'package:cloud_firestore/cloud_firestore.dart';

/// Preview de conversa para lista rápida (users/{uid}/conversationPreviews).
class ConversationPreview {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final String? lastMessageText;
  final Timestamp? lastMessageAt;
  final String? lastSenderId;
  final int unreadCount;
  final Timestamp updatedAt;
  final String type;
  final bool isPending;
  final int? requestCycle;

  const ConversationPreview({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastSenderId,
    this.unreadCount = 0,
    required this.updatedAt,
    this.type = 'direct',
    this.isPending = false,
    this.requestCycle,
  });

  /// Cria ConversationPreview a partir de DocumentSnapshot
  factory ConversationPreview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final otherUserId = data['otherUserId'];
    final otherUserName = data['otherUserName'];
    final otherUserPhoto = data['otherUserPhoto'];
    final type = data['type'];
    final requestCycle = data['requestCycle'];

    return ConversationPreview(
      id: doc.id,
      otherUserId: otherUserId is String ? otherUserId : '',
      otherUserName: otherUserName is String && otherUserName.trim().isNotEmpty
          ? otherUserName.trim()
          : 'Usuario',
      otherUserPhoto: otherUserPhoto is String ? otherUserPhoto : null,
      lastMessageText: data['lastMessageText'] as String?,
      lastMessageAt: data['lastMessageAt'] as Timestamp?,
      lastSenderId: data['lastSenderId'] as String?,
      unreadCount: data['unreadCount'] as int? ?? 0,
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      type: type is String && type.trim().isNotEmpty ? type.trim() : 'direct',
      isPending: data['isPending'] as bool? ?? false,
      requestCycle: requestCycle is num ? requestCycle.toInt() : null,
    );
  }
}
