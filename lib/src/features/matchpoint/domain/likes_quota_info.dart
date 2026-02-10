/// Informações de quota de likes diários.
/// Domain layer — sem dependência de infraestrutura.
class LikesQuotaInfo {
  final int remaining;
  final int limit;
  final DateTime resetTime;

  LikesQuotaInfo({
    required this.remaining,
    required this.limit,
    required this.resetTime,
  });

  factory LikesQuotaInfo.fromJson(Map<String, dynamic> json) {
    return LikesQuotaInfo(
      remaining: json['remaining'] ?? 0,
      limit: json['limit'] ?? 50,
      resetTime: DateTime.parse(json['resetTime']),
    );
  }
}
