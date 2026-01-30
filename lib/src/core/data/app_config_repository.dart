import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart' as fallback;
import '../domain/app_config.dart';

part 'app_config_repository.g.dart';

class AppConfigRepository {
  static const _cacheKey = 'app_config_cache';
  static const _versionKey = 'app_config_version';

  final FirebaseFirestore _firestore;

  AppConfigRepository(this._firestore);

  /// Busca config do Firestore, com cache local e fallback
  Future<AppConfig> fetchConfig() async {
    try {
      // 1. Tentar buscar do Firestore
      final doc = await _firestore.collection('config').doc('app_data').get();

      if (doc.exists && doc.data() != null) {
        final config = AppConfig.fromJson(doc.data()!);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(config.toJson()));
      await prefs.setInt(_versionKey, config.version);
    } catch (e) {
      // print('Erro salvando cache: $e');
    }
  }

  Future<AppConfig?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json != null) {
        return AppConfig.fromJson(jsonDecode(json));
      }
    } catch (e) {
      // print('Erro lendo cache: $e');
    }
    return null;
  }

  AppConfig _buildFallbackConfig() {
    return AppConfig(
      version: 0,
      genres: fallback.genres
          .map(
            (g) => ConfigItem(
              id: g.toLowerCase().replaceAll(' ', '_'),
              label: g,
              order: fallback.genres.indexOf(g),
            ),
          )
          .toList(),
      instruments: fallback.instruments
          .map(
            (i) => ConfigItem(
              id: i.toLowerCase().replaceAll(' ', '_'),
              label: i,
              order: fallback.instruments.indexOf(i),
            ),
          )
          .toList(),
      crewRoles: fallback.crewRoles
          .map(
            (r) => ConfigItem(
              id: r.toLowerCase().replaceAll(' ', '_'),
              label: r,
              order: fallback.crewRoles.indexOf(r),
            ),
          )
          .toList(),
      studioServices: fallback.studioServices
          .map(
            (s) => ConfigItem(
              id: s.toLowerCase().replaceAll(' ', '_'),
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
}

@Riverpod(keepAlive: true)
AppConfigRepository appConfigRepository(Ref ref) {
  return AppConfigRepository(FirebaseFirestore.instance);
}
