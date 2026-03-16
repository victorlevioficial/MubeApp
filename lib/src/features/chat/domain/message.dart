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
  final String? replyToMessageId;
  final String? replyToSenderId;
  final String? replyToText;
  final String? replyToType;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = 'text',
    this.clientMessageId,
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToText,
    this.replyToType,
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
      replyToMessageId: data['replyToMessageId'] as String?,
      replyToSenderId: data['replyToSenderId'] as String?,
      replyToText: data['replyToText'] as String?,
      replyToType: data['replyToType'] as String?,
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
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToType != null) 'replyToType': replyToType,
    };
  }
}
