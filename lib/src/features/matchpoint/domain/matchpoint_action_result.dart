/// Resultado de uma ação no Matchpoint (like/dislike).
/// Domain layer — reutilizável por qualquer data source.
class MatchpointActionResult {
  final bool success;
  final bool isMatch;
  final String? matchId;
  final String? conversationId;
  final int? remainingLikes;
  final String? message;

  MatchpointActionResult({
    required this.success,
    this.isMatch = false,
    this.matchId,
    this.conversationId,
    this.remainingLikes,
    this.message,
  });

  factory MatchpointActionResult.fromJson(Map<String, dynamic> json) {
    return MatchpointActionResult(
      success: json['success'] ?? false,
      isMatch: json['isMatch'] ?? false,
      matchId: json['matchId'],
      conversationId: json['conversationId'],
      remainingLikes: json['remainingLikes'] as int?,
      message: json['message'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MatchpointActionResult &&
        other.success == success &&
        other.isMatch == isMatch &&
        other.matchId == matchId &&
        other.conversationId == conversationId &&
        other.remainingLikes == remainingLikes &&
        other.message == message;
  }

  @override
  int get hashCode {
    return success.hashCode ^
        isMatch.hashCode ^
        matchId.hashCode ^
        conversationId.hashCode ^
        remainingLikes.hashCode ^
        message.hashCode;
  }
}
