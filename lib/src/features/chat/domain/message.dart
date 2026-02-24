import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

/// Representa uma mensagem no chat.
@immutable
class Message {
  final String id;
  final String senderId;
  final String text;
  final Timestamp createdAt;
  final String type;
  final String? clientMessageId;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = 'text',
    this.clientMessageId,
  });

  /// Cria Message a partir de DocumentSnapshot do Firestore
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,

      // Handle optimistic writes locally where serverTimestamp is not yet resolved
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      type: data['type'] as String? ?? 'text',
      clientMessageId: data['clientMessageId'] as String?,
    );
  }

  /// Converte para Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt,
      'type': type,
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    };
  }
}
