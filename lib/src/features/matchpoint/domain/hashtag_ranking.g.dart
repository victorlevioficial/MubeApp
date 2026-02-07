// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hashtag_ranking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HashtagRanking _$HashtagRankingFromJson(Map<String, dynamic> json) =>
    _HashtagRanking(
      id: json['id'] as String,
      hashtag: json['hashtag'] as String,
      displayName: json['displayName'] as String,
      useCount: (json['useCount'] as num).toInt(),
      currentPosition: (json['currentPosition'] as num).toInt(),
      previousPosition: (json['previousPosition'] as num).toInt(),
      trend: json['trend'] as String,
      trendDelta: (json['trendDelta'] as num).toInt(),
      isTrending: json['isTrending'] as bool,
      lastUpdated: _timestampFromJson(json['lastUpdated']),
    );

Map<String, dynamic> _$HashtagRankingToJson(_HashtagRanking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hashtag': instance.hashtag,
      'displayName': instance.displayName,
      'useCount': instance.useCount,
      'currentPosition': instance.currentPosition,
      'previousPosition': instance.previousPosition,
      'trend': instance.trend,
      'trendDelta': instance.trendDelta,
      'isTrending': instance.isTrending,
      'lastUpdated': _timestampToJson(instance.lastUpdated),
    };
