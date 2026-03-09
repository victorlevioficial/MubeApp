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
    final productionRoles = fallback.productionRoles
        .map(
          (r) => ConfigItem(
            id: _toId(r),
            label: r,
            order: fallback.productionRoles.indexOf(r),
          ),
        )
        .toList();
    final stageTechRoles = fallback.stageTechRoles
        .map(
          (r) => ConfigItem(
            id: _toId(r),
            label: r,
            order: fallback.stageTechRoles.indexOf(r),
          ),
        )
        .toList();

    return AppConfig(
      version: 0,
      minAndroidBuildNumber: 0,
      minIosBuildNumber: 0,
      androidStoreUrl: null,
      iosStoreUrl: null,
      genres: fallback.genres
          .map(
            (g) => ConfigItem(
              id: _toId(g),
              label: g,
              order: fallback.genres.indexOf(g),
            ),
          )
          .toList(),
      instruments: fallback.instruments
          .map(
            (i) => ConfigItem(
              id: _toId(i),
              label: i,
              order: fallback.instruments.indexOf(i),
            ),
          )
          .toList(),
      productionRoles: productionRoles,
      stageTechRoles: stageTechRoles,
      crewRoles: fallback.crewRoles
          .map(
            (r) => ConfigItem(
              id: _toId(r),
              label: r,
              order: fallback.crewRoles.indexOf(r),
            ),
          )
          .toList(),
      studioServices: fallback.studioServices
          .map(
            (s) => ConfigItem(
              id: _toId(s),
              label: s,
              order: fallback.studioServices.indexOf(s),
            ),
          )
          .toList(),
      professionalCategories: fallback.professionalCategories
          .map(
            (c) => ConfigItem(
              id: c['id'] as String,
              label: c['label'] as String,
              // icon logic omitted as fallback doesn't imply exact storage needing icons here for now,
              // but let's keep it simple.
            ),
          )
          .toList(),
    );
  }

  AppConfig _normalizeConfig(AppConfig config) {
    final fallbackConfig = _buildFallbackConfig();

    final productionRoles = config.productionRoles.isNotEmpty
        ? config.productionRoles
        : _pickRolesFromUnion(
            config.crewRoles,
            fallback.productionRoles,
          ).ifEmpty(fallbackConfig.productionRoles);
    final stageTechRoles = config.stageTechRoles.isNotEmpty
        ? config.stageTechRoles
        : _pickRolesFromUnion(
            config.crewRoles,
            fallback.stageTechRoles,
          ).ifEmpty(fallbackConfig.stageTechRoles);

    final crewRoles = config.crewRoles.isNotEmpty
        ? config.crewRoles
        : [...productionRoles, ...stageTechRoles];

    final categoryIds = config.professionalCategories.map((c) => c.id).toSet();
    final hasSplitCategories =
        categoryIds.contains('production') &&
        categoryIds.contains('stage_tech');

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
      professionalCategories: hasSplitCategories
          ? config.professionalCategories
          : fallbackConfig.professionalCategories,
    );
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
