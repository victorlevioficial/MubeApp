import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

/// Item de configuração com id, label, ordem e aliases para matching
@freezed
abstract class ConfigItem with _$ConfigItem {
  const factory ConfigItem({
    required String id,
    required String label,
    @Default(0) int order,
    String? icon,
    @Default([]) List<String> aliases,
  }) = _ConfigItem;

  factory ConfigItem.fromJson(Map<String, dynamic> json) =>
      _$ConfigItemFromJson(json);
}

/// Configuração completa do app
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    @Default(0) int version,
    @Default([]) List<ConfigItem> genres,
    @Default([]) List<ConfigItem> instruments,
    @Default([]) List<ConfigItem> crewRoles,
    @Default([]) List<ConfigItem> studioServices,
    @Default([]) List<ConfigItem> professionalCategories,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}
