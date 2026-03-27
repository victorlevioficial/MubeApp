import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../constants/app_constants.dart' as fallback;
import '../domain/app_config.dart';
import '../providers/firebase_providers.dart';

part 'app_config_repository.g.dart';

class AppConfigRepository {
  static const _cacheKey = 'app_config_cache';
  static const _versionKey = 'app_config_version';

  final FirebaseFirestore _firestore;
  final SharedPreferencesLoader _loadPreferences;

  AppConfigRepository(
    this._firestore, {
    required SharedPreferencesLoader loadPreferences,
  }) : _loadPreferences = loadPreferences;

  /// Busca config do Firestore, com cache local e fallback
  Future<AppConfig> fetchConfig() async {
    try {
      // 1. Tentar buscar do Firestore
      final doc = await _firestore.collection('config').doc('app_data').get();

      if (doc.exists && doc.data() != null) {
        final config = _normalizeConfig(AppConfig.fromJson(doc.data()!));
        await _saveToCache(config);
        return config;
      }
    } catch (e) {
      // Falha silenciosa no fetch, tenta cache
      // print('Erro buscando config do Firestore: $e');
    }

    // 2. Tentar cache local
    final cached = await _loadFromCache();
    if (cached != null) return cached;

    // 3. Fallback para constantes
    return _buildFallbackConfig();
  }

  Future<void> _saveToCache(AppConfig config) async {
    try {
      final prefs = await _loadPreferences();
      await prefs.setString(_cacheKey, jsonEncode(config.toJson()));
      await prefs.setInt(_versionKey, config.version);
    } catch (e) {
      // print('Erro salvando cache: $e');
    }
  }

  Future<AppConfig?> _loadFromCache() async {
    try {
      final prefs = await _loadPreferences();
      final json = prefs.getString(_cacheKey);
      if (json != null) {
        return _normalizeConfig(AppConfig.fromJson(jsonDecode(json)));
      }
    } catch (e) {
      // print('Erro lendo cache: $e');
    }
    return null;
  }

  AppConfig _buildFallbackConfig() {
    return AppConfig(
      version: 0,
      minAndroidBuildNumber: 0,
      minIosBuildNumber: 0,
      androidStoreUrl: null,
      iosStoreUrl: null,
      genres: _itemsFromLabels(fallback.genres),
      instruments: _itemsFromLabels(fallback.instruments),
      productionRoles: _itemsFromLabels(fallback.productionRoles),
      stageTechRoles: _itemsFromLabels(fallback.stageTechRoles),
      crewRoles: _itemsFromLabels([
        ...fallback.productionRoles,
        ...fallback.stageTechRoles,
      ]),
      audiovisualRoles: _itemsFromLabels(fallback.audiovisualRoles),
      educationRoles: _itemsFromLabels(fallback.educationRoles),
      luthierRoles: _itemsFromLabels(fallback.luthierRoles),
      performanceRoles: _itemsFromLabels(fallback.performanceRoles),
      studioServices: _itemsFromLabels(fallback.studioServices),
      professionalCategories: fallback.professionalCategories
          .map(
            (c) =>
                ConfigItem(id: c['id'] as String, label: c['label'] as String),
          )
          .toList(),
    );
  }

  AppConfig _normalizeConfig(AppConfig config) {
    final fallbackConfig = _buildFallbackConfig();

    final productionRoles = config.productionRoles.isNotEmpty
        ? _mergeConfigItems(
            config.productionRoles,
            fallbackConfig.productionRoles,
          )
        : _pickRolesFromUnion(
            config.crewRoles,
            fallback.productionRoles,
          ).ifEmpty(fallbackConfig.productionRoles);
    final stageTechRoles = config.stageTechRoles.isNotEmpty
        ? _mergeConfigItems(
            config.stageTechRoles,
            fallbackConfig.stageTechRoles,
          )
        : _pickRolesFromUnion(
            config.crewRoles,
            fallback.stageTechRoles,
          ).ifEmpty(fallbackConfig.stageTechRoles);
    final audiovisualRoles = _mergeConfigItems(
      config.audiovisualRoles,
      fallbackConfig.audiovisualRoles,
    );
    final educationRoles = _mergeConfigItems(
      config.educationRoles,
      fallbackConfig.educationRoles,
    );
    final luthierRoles = _mergeConfigItems(
      config.luthierRoles,
      fallbackConfig.luthierRoles,
    );
    final performanceRoles = _mergeConfigItems(
      config.performanceRoles,
      fallbackConfig.performanceRoles,
    );

    final crewRoles = config.crewRoles.isNotEmpty
        ? config.crewRoles
        : [...productionRoles, ...stageTechRoles];
    final professionalCategories = _mergeConfigItems(
      config.professionalCategories,
      fallbackConfig.professionalCategories,
    );

    return config.copyWith(
      minAndroidBuildNumber: _normalizeMinimumBuildNumber(
        config.minAndroidBuildNumber,
      ),
      minIosBuildNumber: _normalizeMinimumBuildNumber(config.minIosBuildNumber),
      androidStoreUrl: _normalizeStoreUrl(config.androidStoreUrl),
      iosStoreUrl: _normalizeStoreUrl(config.iosStoreUrl),
      productionRoles: productionRoles,
      stageTechRoles: stageTechRoles,
      crewRoles: crewRoles,
      audiovisualRoles: audiovisualRoles,
      educationRoles: educationRoles,
      luthierRoles: luthierRoles,
      performanceRoles: performanceRoles,
      professionalCategories: professionalCategories,
    );
  }

  List<ConfigItem> _itemsFromLabels(List<String> labels) {
    return labels.asMap().entries.map((entry) {
      final label = entry.value;
      return ConfigItem(id: _toId(label), label: label, order: entry.key);
    }).toList();
  }

  List<ConfigItem> _mergeConfigItems(
    List<ConfigItem> configured,
    List<ConfigItem> fallbackItems,
  ) {
    if (configured.isEmpty) return fallbackItems;

    final knownIds = configured.map((item) => item.id).toSet();
    return [
      ...configured,
      ...fallbackItems.where((item) => !knownIds.contains(item.id)),
    ];
  }

  List<ConfigItem> _pickRolesFromUnion(
    List<ConfigItem> source,
    List<String> targetLabels,
  ) {
    if (source.isEmpty) return const [];

    final wanted = targetLabels.map(_toId).toSet();
    return source.where((item) {
      final itemId = _toId(item.id);
      final labelId = _toId(item.label);
      return wanted.contains(itemId) || wanted.contains(labelId);
    }).toList();
  }

  String _toId(Object? value) {
    return removeDiacritics(value.toString())
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  int _normalizeMinimumBuildNumber(int value) {
    if (value < 0) return 0;
    return value;
  }

  String? _normalizeStoreUrl(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

extension _ConfigItemListCompat on List<ConfigItem> {
  List<ConfigItem> ifEmpty(List<ConfigItem> fallback) =>
      isEmpty ? fallback : this;
}

@Riverpod(keepAlive: true)
AppConfigRepository appConfigRepository(Ref ref) {
  return AppConfigRepository(
    ref.watch(firebaseFirestoreProvider),
    loadPreferences: ref.watch(sharedPreferencesLoaderProvider),
  );
}
