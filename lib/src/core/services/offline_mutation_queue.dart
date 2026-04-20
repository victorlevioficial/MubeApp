import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../providers/firebase_providers.dart';

enum OfflineMutationType { favoriteAdd, favoriteRemove, gigApply }

String favoriteMutationScopeKey(String targetId) => 'favorite:$targetId';

String gigApplyMutationScopeKey(String gigId) => 'gig_apply:$gigId';

@immutable
class OfflineMutation {
  const OfflineMutation({
    required this.id,
    required this.type,
    required this.scopeKey,
    required this.payload,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.retryCount = 0,
  });

  final String id;
  final OfflineMutationType type;
  final String scopeKey;
  final Map<String, dynamic> payload;
  final int createdAtMs;
  final int updatedAtMs;
  final int retryCount;

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  DateTime get updatedAt => DateTime.fromMillisecondsSinceEpoch(updatedAtMs);

  String? get favoriteTargetId => payload['target_id'] as String?;

  String? get gigId => payload['gig_id'] as String?;

  String? get gigMessage => payload['message'] as String?;

  String? get gigTitle => payload['gig_title'] as String?;

  bool get isFavoriteMutation =>
      type == OfflineMutationType.favoriteAdd ||
      type == OfflineMutationType.favoriteRemove;

  bool get favoriteDesiredStatus => type == OfflineMutationType.favoriteAdd;

  OfflineMutation copyWith({
    String? id,
    OfflineMutationType? type,
    String? scopeKey,
    Map<String, dynamic>? payload,
    int? createdAtMs,
    int? updatedAtMs,
    int? retryCount,
  }) {
    return OfflineMutation(
      id: id ?? this.id,
      type: type ?? this.type,
      scopeKey: scopeKey ?? this.scopeKey,
      payload: payload ?? this.payload,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _typeToStorageValue(type),
      'scopeKey': scopeKey,
      'payload': payload,
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
      'retryCount': retryCount,
    };
  }

  factory OfflineMutation.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    final payload = rawPayload is Map<String, dynamic>
        ? rawPayload
        : rawPayload is Map
        ? rawPayload.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    final type = _typeFromStorageValue(json['type'] as String?);
    final scopeKey =
        (json['scopeKey'] as String?)?.trim() ??
        _scopeKeyForFallback(type, payload);
    final createdAtMs = _readInt(json['createdAtMs']) ?? 0;
    final updatedAtMs = _readInt(json['updatedAtMs']) ?? createdAtMs;
    final id = (json['id'] as String?)?.trim().isNotEmpty == true
        ? (json['id'] as String).trim()
        : scopeKey;

    return OfflineMutation(
      id: id,
      type: type,
      scopeKey: scopeKey,
      payload: payload,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      retryCount: _readInt(json['retryCount']) ?? 0,
    );
  }

  static String _scopeKeyForFallback(
    OfflineMutationType type,
    Map<String, dynamic> payload,
  ) {
    switch (type) {
      case OfflineMutationType.favoriteAdd:
      case OfflineMutationType.favoriteRemove:
        final targetId = (payload['target_id'] as String?)?.trim() ?? '';
        return favoriteMutationScopeKey(targetId);
      case OfflineMutationType.gigApply:
        final gigId = (payload['gig_id'] as String?)?.trim() ?? '';
        return gigApplyMutationScopeKey(gigId);
    }
  }
}

class OfflineMutationQueue {
  OfflineMutationQueue(this._loadPreferences);

  static const _storageKeyPrefix = 'offline_mutations.';

  final SharedPreferencesLoader _loadPreferences;

  String storageKeyForUser(String userId) => '$_storageKeyPrefix$userId';

  Future<List<OfflineMutation>> load(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const [];

    final prefs = await _loadPreferences();
    final payload = prefs.getString(storageKeyForUser(normalizedUserId));
    if (payload == null || payload.trim().isEmpty) {
      return const [];
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(payload);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map(
          (entry) => OfflineMutation.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((entry) => entry.scopeKey.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> save(String userId, List<OfflineMutation> entries) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final prefs = await _loadPreferences();
    if (entries.isEmpty) {
      await prefs.remove(storageKeyForUser(normalizedUserId));
      return;
    }

    final payload = jsonEncode(entries.map((entry) => entry.toJson()).toList());
    await prefs.setString(storageKeyForUser(normalizedUserId), payload);
  }
}

class OfflineMutationStore extends Notifier<List<OfflineMutation>> {
  OfflineMutationQueue get _queue => ref.read(offlineMutationQueueProvider);

  String? _currentUserId;
  bool _isLoaded = false;
  int _loadGeneration = 0;

  List<OfflineMutation> get entries =>
      List<OfflineMutation>.unmodifiable(state);

  String? get currentUserId => _currentUserId;

  bool get isLoaded => _isLoaded;

  @override
  List<OfflineMutation> build() {
    Future<void> syncFromAuth(AsyncValue<User?> authState) async {
      await ensureUserLoaded(authState.value?.uid);
    }

    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (_, next) {
      unawaited(syncFromAuth(next));
    });
    unawaited(syncFromAuth(ref.read(authStateChangesProvider)));

    return const [];
  }

  Future<void> ensureUserLoaded(String? userId) async {
    final normalizedUserId = userId?.trim();
    if ((_currentUserId ?? '') == (normalizedUserId ?? '') && _isLoaded) {
      return;
    }

    await loadForUser(normalizedUserId);
  }

  Future<void> loadForUser(String? userId) async {
    final loadGeneration = ++_loadGeneration;
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      _currentUserId = null;
      state = const [];
      _isLoaded = true;
      return;
    }

    _currentUserId = normalizedUserId;
    _isLoaded = false;
    final loadedEntries = await _queue.load(normalizedUserId);
    if (loadGeneration != _loadGeneration ||
        _currentUserId != normalizedUserId) {
      return;
    }

    state = loadedEntries;
    _sortEntries();
    _isLoaded = true;
  }

  Map<String, bool> favoriteDesiredStatusByTarget() {
    final pending = <String, bool>{};
    for (final entry in state) {
      if (!entry.isFavoriteMutation) continue;
      final targetId = entry.favoriteTargetId?.trim();
      if (targetId == null || targetId.isEmpty) continue;
      pending[targetId] = entry.favoriteDesiredStatus;
    }
    return pending;
  }

  OfflineMutation? pendingGigApplyFor(String gigId) {
    final scopeKey = gigApplyMutationScopeKey(gigId.trim());
    for (final entry in state) {
      if (entry.scopeKey == scopeKey &&
          entry.type == OfflineMutationType.gigApply) {
        return entry;
      }
    }
    return null;
  }

  List<OfflineMutation> pendingGigApplies() {
    return state
        .where((entry) => entry.type == OfflineMutationType.gigApply)
        .toList(growable: false);
  }

  Future<void> upsertFavoriteDesiredState({
    required String targetId,
    required bool isFavorite,
  }) async {
    final normalizedTargetId = targetId.trim();
    if (normalizedTargetId.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final scopeKey = favoriteMutationScopeKey(normalizedTargetId);
    final existing = _findByScopeKey(scopeKey);

    await _upsert(
      OfflineMutation(
        id: existing?.id ?? scopeKey,
        type: isFavorite
            ? OfflineMutationType.favoriteAdd
            : OfflineMutationType.favoriteRemove,
        scopeKey: scopeKey,
        payload: {'target_id': normalizedTargetId},
        createdAtMs: existing?.createdAtMs ?? now,
        updatedAtMs: now,
        retryCount: existing?.retryCount ?? 0,
      ),
    );
  }

  Future<void> upsertGigApply({
    required String gigId,
    required String message,
    String? gigTitle,
  }) async {
    final normalizedGigId = gigId.trim();
    final trimmedMessage = message.trim();
    if (normalizedGigId.isEmpty || trimmedMessage.isEmpty) return;

    final scopeKey = gigApplyMutationScopeKey(normalizedGigId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = _findByScopeKey(scopeKey);

    await _upsert(
      OfflineMutation(
        id: existing?.id ?? scopeKey,
        type: OfflineMutationType.gigApply,
        scopeKey: scopeKey,
        payload: {
          'gig_id': normalizedGigId,
          'message': trimmedMessage,
          if (gigTitle != null && gigTitle.trim().isNotEmpty)
            'gig_title': gigTitle.trim(),
        },
        createdAtMs: existing?.createdAtMs ?? now,
        updatedAtMs: now,
        retryCount: existing?.retryCount ?? 0,
      ),
    );
  }

  Future<void> removeScopeKey(String scopeKey) async {
    final normalizedScopeKey = scopeKey.trim();
    if (normalizedScopeKey.isEmpty) return;

    final nextEntries = state
        .where((entry) => entry.scopeKey != normalizedScopeKey)
        .toList(growable: false);
    await _replaceEntries(nextEntries);
  }

  Future<void> markRetry(String scopeKey) async {
    final normalizedScopeKey = scopeKey.trim();
    final existing = _findByScopeKey(normalizedScopeKey);
    if (existing == null) return;

    await _upsert(
      existing.copyWith(
        retryCount: existing.retryCount + 1,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _upsert(OfflineMutation entry) async {
    final nextEntries = <OfflineMutation>[
      ...state.where((item) => item.scopeKey != entry.scopeKey),
      entry,
    ];
    await _replaceEntries(nextEntries);
  }

  Future<void> _replaceEntries(List<OfflineMutation> nextEntries) async {
    final userId = _currentUserId;
    state = List<OfflineMutation>.from(nextEntries, growable: false);
    _sortEntries();

    if (userId == null || userId.isEmpty) {
      return;
    }

    await _queue.save(userId, state);
  }

  OfflineMutation? _findByScopeKey(String scopeKey) {
    final normalizedScopeKey = scopeKey.trim();
    for (final entry in state) {
      if (entry.scopeKey == normalizedScopeKey) {
        return entry;
      }
    }
    return null;
  }

  void _sortEntries() {
    state = List<OfflineMutation>.from(state, growable: false)
      ..sort((a, b) {
        final createdComparison = a.createdAtMs.compareTo(b.createdAtMs);
        if (createdComparison != 0) {
          return createdComparison;
        }
        return a.scopeKey.compareTo(b.scopeKey);
      });
  }
}

final offlineMutationQueueProvider = Provider<OfflineMutationQueue>((ref) {
  return OfflineMutationQueue(ref.read(sharedPreferencesLoaderProvider));
});

final offlineMutationStoreProvider =
    NotifierProvider<OfflineMutationStore, List<OfflineMutation>>(
      OfflineMutationStore.new,
    );

String _typeToStorageValue(OfflineMutationType type) {
  switch (type) {
    case OfflineMutationType.favoriteAdd:
      return 'favorite_add';
    case OfflineMutationType.favoriteRemove:
      return 'favorite_remove';
    case OfflineMutationType.gigApply:
      return 'gig_apply';
  }
}

OfflineMutationType _typeFromStorageValue(String? value) {
  switch (value) {
    case 'favorite_remove':
      return OfflineMutationType.favoriteRemove;
    case 'gig_apply':
      return OfflineMutationType.gigApply;
    case 'favorite_add':
    default:
      return OfflineMutationType.favoriteAdd;
  }
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
