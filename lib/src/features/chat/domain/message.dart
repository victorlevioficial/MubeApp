/// Modelo de mensagem individual do chat
class Message {
  final String id;
  final String senderId;
  final String text;
  final int timestamp;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromJson(String id, Map<dynamic, dynamic> json) {
    return Message(
      id: id,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'senderId': senderId, 'text': text, 'timestamp': timestamp};
  }
}
