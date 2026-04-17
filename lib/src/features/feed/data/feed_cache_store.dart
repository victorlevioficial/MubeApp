import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';

class FeedCacheSnapshot {
  const FeedCacheSnapshot({
    required this.cachedAt,
    required this.currentFilter,
    required this.items,
    required this.featuredItems,
    required this.sectionItems,
  });

  final DateTime cachedAt;
  final String currentFilter;
  final List<FeedItem> items;
  final List<FeedItem> featuredItems;
  final Map<FeedSectionType, List<FeedItem>> sectionItems;

  Map<String, dynamic> toJson() {
    return {
      'cachedAtMs': cachedAt.millisecondsSinceEpoch,
      'currentFilter': currentFilter,
      'items': items.map(_feedItemToJson).toList(growable: false),
      'featuredItems': featuredItems
          .map(_feedItemToJson)
          .toList(growable: false),
      'sectionItems': sectionItems.map(
        (key, value) => MapEntry(
          key.name,
          value.map(_feedItemToJson).toList(growable: false),
        ),
      ),
    };
  }

  factory FeedCacheSnapshot.fromJson(Map<String, dynamic> json) {
    final rawSectionItems = json['sectionItems'];
    final sectionItems = <FeedSectionType, List<FeedItem>>{};
    if (rawSectionItems is Map) {
      for (final entry in rawSectionItems.entries) {
        final sectionType = FeedSectionType.values.where(
          (value) => value.name == entry.key.toString(),
        );
        if (sectionType.isEmpty) {
          continue;
        }

        final rawItems = entry.value;
        if (rawItems is! List) {
          continue;
        }

        sectionItems[sectionType.first] = rawItems
            .whereType<Map>()
            .map(
              (item) => _feedItemFromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList(growable: false);
      }
    }

    return FeedCacheSnapshot(
      cachedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['cachedAtMs'] as num?)?.toInt() ?? 0,
      ),
      currentFilter:
          (json['currentFilter'] as String?)?.trim().isNotEmpty == true
          ? (json['currentFilter'] as String).trim()
          : 'Todos',
      items: _readFeedItems(json['items']),
      featuredItems: _readFeedItems(json['featuredItems']),
      sectionItems: sectionItems,
    );
  }

  static List<FeedItem> _readFeedItems(Object? rawItems) {
    if (rawItems is! List) {
      return const [];
    }

    return rawItems
        .whereType<Map>()
        .map(
          (item) => _feedItemFromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }
}

class FeedCacheStore {
  FeedCacheStore(this._loadPreferences);

  static const _storageKeyPrefix = 'feed_cache.';

  final SharedPreferencesLoader _loadPreferences;

  String storageKeyForUser(String userId) => '$_storageKeyPrefix$userId';

  Future<FeedCacheSnapshot?> load(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;

    final prefs = await _loadPreferences();
    final payload = prefs.getString(storageKeyForUser(normalizedUserId));
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(payload);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;

    return FeedCacheSnapshot.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<void> save(String userId, FeedCacheSnapshot snapshot) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final prefs = await _loadPreferences();
    await prefs.setString(
      storageKeyForUser(normalizedUserId),
      jsonEncode(snapshot.toJson()),
    );
  }

  Future<void> clear(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final prefs = await _loadPreferences();
    await prefs.remove(storageKeyForUser(normalizedUserId));
  }
}

final feedCacheStoreProvider = Provider<FeedCacheStore>((ref) {
  return FeedCacheStore(ref.read(sharedPreferencesLoaderProvider));
});

Map<String, dynamic> _feedItemToJson(FeedItem item) {
  return {
    'uid': item.uid,
    'nome': item.nome,
    'nomeArtistico': item.nomeArtistico,
    'foto': item.foto,
    'categoria': item.categoria,
    'generosMusicais': item.generosMusicais,
    'tipoPerfil': item.tipoPerfil,
    'location': item.location,
    'likeCount': item.likeCount,
    'skills': item.skills,
    'subCategories': item.subCategories,
    'offersRemoteRecording': item.offersRemoteRecording,
    'distanceKm': item.distanceKm,
  };
}

FeedItem _feedItemFromJson(Map<String, dynamic> json) {
  final rawLocation = json['location'];
  final location = rawLocation is Map<String, dynamic>
      ? rawLocation
      : rawLocation is Map
      ? rawLocation.map((key, value) => MapEntry(key.toString(), value))
      : null;

  return FeedItem(
    uid: (json['uid'] as String?)?.trim() ?? '',
    nome: (json['nome'] as String?)?.trim() ?? '',
    nomeArtistico: (json['nomeArtistico'] as String?)?.trim(),
    foto: (json['foto'] as String?)?.trim(),
    categoria: (json['categoria'] as String?)?.trim(),
    generosMusicais: (json['generosMusicais'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    tipoPerfil: (json['tipoPerfil'] as String?)?.trim() ?? '',
    location: location,
    likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    skills: (json['skills'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    subCategories: (json['subCategories'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    offersRemoteRecording: json['offersRemoteRecording'] == true,
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
  );
}
