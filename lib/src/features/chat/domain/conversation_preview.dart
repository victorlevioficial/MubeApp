/// Modelo de preview de conversa para a lista de conversas
class ConversationPreview {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final String lastMessage;
  final int lastMessageTime;
  final String lastSenderId;
  final int unreadCount;

  const ConversationPreview({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastSenderId,
    required this.unreadCount,
  });

  factory ConversationPreview.fromJson(
    String conversationId,
    Map<dynamic, dynamic> json,
  ) {
    return ConversationPreview(
      conversationId: conversationId,
      otherUserId: json['otherUserId'] as String? ?? '',
      otherUserName: json['otherUserName'] as String? ?? 'Usuário',
      otherUserPhoto: json['otherUserPhoto'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: json['lastMessageTime'] as int? ?? 0,
      lastSenderId: json['lastSenderId'] as String? ?? '',
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhoto': otherUserPhoto,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
    };
  }
}
