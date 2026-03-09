// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConfigItem _$ConfigItemFromJson(Map<String, dynamic> json) => _ConfigItem(
  id: json['id'] as String,
  label: json['label'] as String,
  order: (json['order'] as num?)?.toInt() ?? 0,
  icon: json['icon'] as String?,
  aliases:
      (json['aliases'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ConfigItemToJson(_ConfigItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'order': instance.order,
      'icon': instance.icon,
      'aliases': instance.aliases,
    };

_AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => _AppConfig(
  version: (json['version'] as num?)?.toInt() ?? 0,
  minAndroidBuildNumber:
      (json['min_android_build_number'] as num?)?.toInt() ?? 0,
  minIosBuildNumber: (json['min_ios_build_number'] as num?)?.toInt() ?? 0,
  androidStoreUrl: json['android_store_url'] as String?,
  iosStoreUrl: json['ios_store_url'] as String?,
  genres:
      (json['genres'] as List<dynamic>?)
          ?.map((e) => ConfigItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  instruments:
      (json['instruments'] as List<dynamic>?)
          ?.map((e) => ConfigItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  productionRoles:
      (json['productionRoles'] as List<dynamic>?)
          ?.map((e) => ConfigItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  stageTechRoles:
      (json['stageTechRoles'] as List<dynamic>?)
          ?.map((e) => ConfigItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  crewRoles:
      (json['crewRoles'] as List<dynamic>?)
          ?.map((e) => ConfigItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  studioServices:
      (json['studioServices'] as List<dynamic>?)
          ?.map((e) => ConfigItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  professionalCategories:
      (json['professionalCategories'] as List<dynamic>?)
          ?.map((e) => ConfigItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$AppConfigToJson(_AppConfig instance) =>
    <String, dynamic>{
      'version': instance.version,
      'min_android_build_number': instance.minAndroidBuildNumber,
      'min_ios_build_number': instance.minIosBuildNumber,
      'android_store_url': instance.androidStoreUrl,
      'ios_store_url': instance.iosStoreUrl,
      'genres': instance.genres,
      'instruments': instance.instruments,
      'productionRoles': instance.productionRoles,
      'stageTechRoles': instance.stageTechRoles,
      'crewRoles': instance.crewRoles,
      'studioServices': instance.studioServices,
      'professionalCategories': instance.professionalCategories,
    };
