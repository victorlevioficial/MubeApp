// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchFilters _$SearchFiltersFromJson(Map<String, dynamic> json) =>
    _SearchFilters(
      query: json['query'] as String?,
      type: $enumDecodeNullable(_$AppUserTypeEnumMap, json['type']),
      city: json['city'] as String?,
      state: json['state'] as String?,
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maxDistance: (json['maxDistance'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SearchFiltersToJson(_SearchFilters instance) =>
    <String, dynamic>{
      'query': instance.query,
      'type': _$AppUserTypeEnumMap[instance.type],
      'city': instance.city,
      'state': instance.state,
      'genres': instance.genres,
      'maxDistance': instance.maxDistance,
    };

const _$AppUserTypeEnumMap = {
  AppUserType.professional: 'profissional',
  AppUserType.studio: 'estudio',
  AppUserType.band: 'banda',
  AppUserType.contractor: 'contratante',
};
