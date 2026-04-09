import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../domain/matchpoint_swipe_command.dart';

@immutable
class PersistedMatchpointSwipeCommand {
  final String commandId;
  final MatchpointSwipeCommand command;

  const PersistedMatchpointSwipeCommand({
    required this.commandId,
    required this.command,
  });

  Map<String, dynamic> toJson() {
    return {'commandId': commandId, 'command': command.toJson()};
  }

  factory PersistedMatchpointSwipeCommand.fromJson(Map<String, dynamic> json) {
    final rawCommand = json['command'];
    final commandJson = rawCommand is Map<String, dynamic>
        ? rawCommand
        : rawCommand is Map
        ? rawCommand.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    return PersistedMatchpointSwipeCommand(
      commandId: json['commandId'] as String? ?? '',
      command: MatchpointSwipeCommand.fromJson(commandJson),
    );
  }
}

class MatchpointSwipeOutboxStore {
  static const _storageKeyPrefix = 'matchpoint_swipe_outbox.';

  final SharedPreferencesLoader _loadPreferences;

  MatchpointSwipeOutboxStore(this._loadPreferences);

  String storageKeyForUser(String userId) => '$_storageKeyPrefix$userId';

  Future<List<PersistedMatchpointSwipeCommand>> load(String userId) async {
    if (userId.trim().isEmpty) return const [];
    final prefs = await _loadPreferences();
    final payload = prefs.getString(storageKeyForUser(userId));
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
          (entry) => PersistedMatchpointSwipeCommand.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((entry) => entry.commandId.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> enqueue({
    required String userId,
    required PersistedMatchpointSwipeCommand entry,
  }) async {
    final current = await load(userId);
    final next = <PersistedMatchpointSwipeCommand>[
      ...current.where((item) => item.commandId != entry.commandId),
      entry,
    ];
    await save(userId, next);
  }

  Future<void> remove({
    required String userId,
    required String commandId,
  }) async {
    final current = await load(userId);
    final next = current
        .where((entry) => entry.commandId != commandId)
        .toList(growable: false);
    await save(userId, next);
  }

  Future<void> save(
    String userId,
    List<PersistedMatchpointSwipeCommand> entries,
  ) async {
    if (userId.trim().isEmpty) return;
    final prefs = await _loadPreferences();
    if (entries.isEmpty) {
      await prefs.remove(storageKeyForUser(userId));
      return;
    }

    final payload = jsonEncode(entries.map((entry) => entry.toJson()).toList());
    await prefs.setString(storageKeyForUser(userId), payload);
  }
}

final matchpointSwipeOutboxStoreProvider = Provider<MatchpointSwipeOutboxStore>(
  (ref) {
    return MatchpointSwipeOutboxStore(
      ref.read(sharedPreferencesLoaderProvider),
    );
  },
);
