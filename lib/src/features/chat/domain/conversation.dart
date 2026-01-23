import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

/// Representa uma conversa entre 2 usuários.
@immutable
class Conversation {
  final String id;
  final List<String> participants;
  final Map<String, bool> participantsMap;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? lastMessageText;
  final Timestamp? lastMessageAt;
  final String? lastSenderId;

  const Conversation({
    required this.id,
    required this.participants,
    required this.participantsMap,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastSenderId,
  });

  /// Cria Conversation a partir de DocumentSnapshot
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List),
      participantsMap: Map<String, bool>.from(data['participantsMap'] as Map),
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
      lastMessageText: data['lastMessageText'] as String?,
      lastMessageAt: data['lastMessageAt'] as Timestamp?,
      lastSenderId: data['lastSenderId'] as String?,
    );
  }
}
