import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hashtag_ranking.freezed.dart';
part 'hashtag_ranking.g.dart';

/// Modelo de ranking de hashtags para o Matchpoint
@freezed
abstract class HashtagRanking with _$HashtagRanking {
  const factory HashtagRanking({
    required String id,
    required String hashtag,
    required String displayName,
    required int useCount,
    required int currentPosition,
    required int previousPosition,
    required String trend,
    required int trendDelta,
    required bool isTrending,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    required Timestamp lastUpdated,
  }) = _HashtagRanking;

  factory HashtagRanking.fromJson(Map<String, dynamic> json) =>
      _$HashtagRankingFromJson(json);

  /// Cria a partir de um documento do Firestore
  factory HashtagRanking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HashtagRanking(
      id: doc.id,
      hashtag: data['hashtag'] as String? ?? '',
      displayName: data['display_name'] as String? ?? data['hashtag'] as String? ?? '',
      useCount: data['use_count'] as int? ?? 0,
      currentPosition: data['current_position'] as int? ?? 0,
      previousPosition: data['previous_position'] as int? ?? 0,
      trend: data['trend'] as String? ?? 'stable',
      trendDelta: data['trend_delta'] as int? ?? 0,
      isTrending: data['is_trending'] as bool? ?? false,
      lastUpdated: data['updated_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Cria a partir da resposta da Cloud Function
  factory HashtagRanking.fromCloudFunction(Map<String, dynamic> data) {
    return HashtagRanking(
      id: data['id'] as String? ?? '',
      hashtag: data['hashtag'] as String? ?? '',
      displayName: data['display_name'] as String? ?? data['hashtag'] as String? ?? '',
      useCount: data['use_count'] as int? ?? 0,
      currentPosition: data['current_position'] as int? ?? 0,
      previousPosition: data['previous_position'] as int? ?? 0,
      trend: data['trend'] as String? ?? 'stable',
      trendDelta: data['trend_delta'] as int? ?? 0,
      isTrending: data['is_trending'] as bool? ?? false,
      lastUpdated: Timestamp.now(),
    );
  }
}

/// Converte Timestamp do Firestore para o formato JSON
Timestamp _timestampFromJson(dynamic json) => json as Timestamp;

/// Converte Timestamp para o formato JSON
dynamic _timestampToJson(Timestamp timestamp) => timestamp;

/// Extensão para facilitar o uso do model
extension HashtagRankingX on HashtagRanking {
  /// Retorna a mudança de posição (positivo = subiu, negativo = desceu)
  int get positionChange => previousPosition - currentPosition;

  /// Retorna se subiu no ranking
  bool get isUp => trend == 'up';

  /// Retorna se desceu no ranking
  bool get isDown => trend == 'down';

  /// Retorna se manteve posição
  bool get isStable => trend == 'stable';

  /// Retorna o emoji de tendência
  String get trendEmoji {
    if (isUp) return '↑';
    if (isDown) return '↓';
    return '→';
  }

  /// Retorna a cor da tendência (para uso no UI)
  String get trendColor {
    if (isUp) return 'success';
    if (isDown) return 'error';
    return 'neutral';
  }
}
