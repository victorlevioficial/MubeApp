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
  });

  /// Cria ConversationPreview a partir de DocumentSnapshot
  factory ConversationPreview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationPreview(
      id: doc.id,
      otherUserId: data['otherUserId'] as String,
      otherUserName: data['otherUserName'] as String,
      otherUserPhoto: data['otherUserPhoto'] as String?,
      lastMessageText: data['lastMessageText'] as String?,
      lastMessageAt: data['lastMessageAt'] as Timestamp?,
      lastSenderId: data['lastSenderId'] as String?,
      unreadCount: data['unreadCount'] as int? ?? 0,
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      type: data['type'] as String? ?? 'direct',
    );
  }
}
