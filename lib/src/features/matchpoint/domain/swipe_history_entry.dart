/// Modelo de entrada do histórico de swipes.
/// Inclui dados do target user para exibição sem lookup adicional.
class SwipeHistoryEntry {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserPhoto;
  final String action; // 'like' ou 'dislike'
  final DateTime timestamp;

  SwipeHistoryEntry({
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserPhoto,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'targetUserPhoto': targetUserPhoto,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SwipeHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SwipeHistoryEntry(
      targetUserId: json['targetUserId'] as String,
      targetUserName: json['targetUserName'] as String? ?? 'Desconhecido',
      targetUserPhoto: json['targetUserPhoto'] as String?,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
