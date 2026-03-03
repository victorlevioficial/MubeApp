import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/domain/app_config.dart';
import 'package:mube/src/core/providers/app_config_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/match_info.dart';
import 'package:mube/src/features/matchpoint/domain/swipe_history_entry.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'matchpoint_controller.g.dart';

final matchpointSelectedTabNotifier = ValueNotifier<int>(0);

class LikesQuotaState {
  final int remaining;
  final int limit;
  final DateTime? resetTime;
  final bool isLoading;

  const LikesQuotaState({
    this.remaining = 50,
    this.limit = 50,
    this.resetTime,
    this.isLoading = false,
  });

  bool get hasReachedLimit => remaining <= 0;

  LikesQuotaState copyWith({
    int? remaining,
    int? limit,
    DateTime? resetTime,
    bool? isLoading,
  }) {
    return LikesQuotaState(
      remaining: remaining ?? this.remaining,
      limit: limit ?? this.limit,
      resetTime: resetTime ?? this.resetTime,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SwipeActionResult {
  final bool success;
  final AppUser? matchedUser;
  final String? conversationId;

  const SwipeActionResult({
    required this.success,
    this.matchedUser,
    this.conversationId,
  });
}

@Riverpod(keepAlive: true)
class MatchpointController extends _$MatchpointController {
  @override
  FutureOr<void> build() {}

  Future<void> saveMatchpointProfile({
    required String intent,
    required List<String> genres,
    required List<String> hashtags,
    required bool isVisibleInHome,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final appUser = ref.read(currentUserProfileProvider).value;
      if (appUser == null) {
        throw Exception('Perfil nao carregado');
      }

      final authRepo = ref.read(authRepositoryProvider);

      final updatedMatchpointProfile = <String, dynamic>{
        ...appUser.matchpointProfile ?? {},
        FirestoreFields.intent: intent,
        FirestoreFields.musicalGenres: genres,
        FirestoreFields.hashtags: hashtags,
        FirestoreFields.isActive: true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final updatedPrivacy = <String, dynamic>{
        ...appUser.privacySettings,
        'visible_in_home': isVisibleInHome,
      };

      final updatedUser = appUser.copyWith(
        matchpointProfile: updatedMatchpointProfile,
        privacySettings: updatedPrivacy,
      );

      final result = await authRepo.updateUser(updatedUser);

      return result.fold((failure) => throw failure.message, (_) {
        unawaited(
          ref
              .read(analyticsServiceProvider)
              .logMatchPointFilter(
                instruments: [],
                genres: genres,
                distance: 0,
              ),
        );
        return null;
      });
    });
  }

  Future<SwipeActionResult> swipeRight(AppUser targetUser) async {
    return _handleSwipe(targetUser, 'like');
  }

  Future<bool> swipeLeft(AppUser targetUser) async {
    final result = await _handleSwipe(targetUser, 'dislike');
    return result.success;
  }

  Future<SwipeActionResult> _handleSwipe(
    AppUser targetUser,
    String type,
  ) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) {
      AppLogger.error('Swipe blocked: missing FirebaseAuth session.');
      state = const AsyncError(
        'Sessao expirada. Faca login novamente.',
        StackTrace.empty,
      );
      return const SwipeActionResult(success: false);
    }

    try {
      final idToken = await currentUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        AppLogger.error('Swipe blocked: missing FirebaseAuth token.');
        state = const AsyncError(
          'Sessao invalida. Faca login novamente.',
          StackTrace.empty,
        );
        return const SwipeActionResult(success: false);
      }
    } catch (e) {
      AppLogger.error('Swipe blocked: failed to read FirebaseAuth token: $e');
      state = AsyncError('Erro de autenticacao: $e', StackTrace.current);
      return const SwipeActionResult(success: false);
    }

    final repo = ref.read(matchpointRepositoryProvider);
    final result = await repo.submitAction(
      targetUserId: targetUser.uid,
      type: type,
    );

    return result.fold(
      (failure) {
        AppLogger.error('Failed to process swipe: $failure');
        state = AsyncError(failure.message, StackTrace.current);
        return const SwipeActionResult(success: false);
      },
      (actionResult) async {
        if (actionResult.remainingLikes != null) {
          ref
              .read(likesQuotaProvider.notifier)
              .updateRemaining(actionResult.remainingLikes!);
        }

        ref.read(swipeHistoryProvider.notifier).addSwipe(targetUser, type);

        if (actionResult.isMatch == true) {
          AppLogger.info("IT'S A MATCH!");
          ref.invalidate(matchesProvider);

          return SwipeActionResult(
            success: true,
            matchedUser: targetUser,
            conversationId: actionResult.conversationId,
          );
        }

        return const SwipeActionResult(success: true);
      },
    );
  }

  Future<void> unmatchUser(String targetUserId) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) return;

    final repo = ref.read(matchpointRepositoryProvider);
    final result = await repo.submitAction(
      targetUserId: targetUserId,
      type: 'dislike',
    );

    result.fold(
      (failure) {
        AppLogger.error('Failed to unmatch user: ${failure.message}');
      },
      (_) {
        AppLogger.info('MatchpointController: unmatched $targetUserId');
        ref.invalidate(matchesProvider);
      },
    );
  }

  Future<void> fetchRemainingLikes() async {
    final repo = ref.read(matchpointRepositoryProvider);
    final result = await repo.getRemainingLikes();

    result.fold(
      (failure) {
        AppLogger.error('Failed to fetch likes quota: ${failure.message}');
      },
      (quota) {
        ref
            .read(likesQuotaProvider.notifier)
            .setQuota(
              remaining: quota.remaining,
              limit: quota.limit,
              resetTime: quota.resetTime,
            );
      },
    );
  }
}

@Riverpod(keepAlive: true)
class LikesQuota extends _$LikesQuota {
  @override
  LikesQuotaState build() {
    return const LikesQuotaState();
  }

  void setQuota({
    required int remaining,
    required int limit,
    required DateTime resetTime,
  }) {
    state = LikesQuotaState(
      remaining: remaining,
      limit: limit,
      resetTime: resetTime,
      isLoading: false,
    );
  }

  void updateRemaining(int remaining) {
    state = state.copyWith(remaining: remaining);
  }

  void decrementOptimistically() {
    if (state.remaining > 0) {
      state = state.copyWith(remaining: state.remaining - 1);
    }
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

@Riverpod(keepAlive: true)
class MatchpointCandidates extends _$MatchpointCandidates {
  @override
  Future<List<AppUser>> build() async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) return [];

    final profileAsync = ref.watch(currentUserProfileProvider);
    final userProfile = profileAsync.value;

    if (profileAsync.isLoading && userProfile == null) {
      AppLogger.info('MatchPoint: waiting for current profile...');
      return [];
    }

    if (userProfile == null) return [];

    final rawGenres = _resolveGenres(userProfile);
    final hashtags = _resolveHashtags(userProfile);
    final appConfig = ref
        .watch(appConfigProvider)
        .maybeWhen(data: (config) => config, orElse: () => null);
    final genres = _buildQueryGenres(rawGenres, appConfig?.genres ?? const []);

    AppLogger.info(
      'MatchPoint filters: rawGenres=$rawGenres queryGenres=$genres hashtags=$hashtags',
    );

    final blockedState = ref.watch(blockedUsersProvider);
    final blockedFromCollection = blockedState.when(
      data: (value) => value,
      loading: () => const <String>[],
      error: (_, _) => const <String>[],
    );

    final blockedUsers = {
      ...userProfile.blockedUsers,
      ...blockedFromCollection,
    }.toList();

    final repo = ref.read(matchpointRepositoryProvider);
    final result = await repo.fetchCandidates(
      currentUser: userProfile,
      genres: genres,
      hashtags: hashtags,
      blockedUsers: blockedUsers,
    );

    return result.fold(
      (failure) {
        AppLogger.error('MatchPoint query error: ${failure.message}');
        throw failure.message;
      },
      (candidates) {
        AppLogger.info(
          'MatchPoint query success: found ${candidates.length} candidates',
        );
        return candidates;
      },
    );
  }

  List<String> _resolveGenres(AppUser userProfile) {
    final matchpointGenres =
        userProfile.matchpointProfile?[FirestoreFields.musicalGenres] ??
        userProfile.matchpointProfile?['musicalGenres'] ??
        userProfile.matchpointProfile?['musical_genres'];
    if (matchpointGenres is List && matchpointGenres.isNotEmpty) {
      return matchpointGenres.whereType<String>().toList();
    }

    final professionalGenres =
        userProfile.dadosProfissional?['generosMusicais'];
    if (professionalGenres is List && professionalGenres.isNotEmpty) {
      return professionalGenres.whereType<String>().toList();
    }

    final bandGenres = userProfile.dadosBanda?['generosMusicais'];
    if (bandGenres is List && bandGenres.isNotEmpty) {
      return bandGenres.whereType<String>().toList();
    }

    return const <String>[];
  }

  List<String> _resolveHashtags(AppUser userProfile) {
    final rawHashtags =
        userProfile.matchpointProfile?[FirestoreFields.hashtags];
    if (rawHashtags is! List || rawHashtags.isEmpty) {
      return const <String>[];
    }

    final seen = <String>{};
    final result = <String>[];
    for (final hashtag in rawHashtags.whereType<String>()) {
      final normalized = hashtag.trim();
      if (normalized.isEmpty) continue;

      final dedupeKey = normalized.toLowerCase();
      if (seen.add(dedupeKey)) {
        result.add(normalized);
      }
    }

    return result;
  }

  List<String> _buildQueryGenres(
    List<String> rawGenres,
    List<ConfigItem> configGenres,
  ) {
    final canonicalIds = <String>[];
    final expanded = <String>[];

    for (final raw in rawGenres) {
      final token = raw.trim();
      if (token.isEmpty) continue;

      final configItem = _findConfigGenre(token, configGenres);
      if (configItem != null) {
        canonicalIds.add(configItem.id);
        expanded.add(configItem.label);
        expanded.addAll(configItem.aliases);
      }
      expanded.add(token);
    }

    final seen = <String>{};
    final queryGenres = <String>[];
    for (final token in [...canonicalIds, ...expanded]) {
      final normalized = token.trim();
      if (normalized.isEmpty) continue;

      final dedupeKey = normalized.toLowerCase();
      if (seen.add(dedupeKey)) {
        queryGenres.add(normalized);
      }
    }

    return queryGenres.take(10).toList();
  }

  ConfigItem? _findConfigGenre(String token, List<ConfigItem> configGenres) {
    final normalized = token.trim().toLowerCase();
    for (final item in configGenres) {
      if (item.id.toLowerCase() == normalized) return item;
      if (item.label.toLowerCase() == normalized) return item;
      if (item.aliases.any((alias) => alias.toLowerCase() == normalized)) {
        return item;
      }
    }
    return null;
  }

  void removeCandidate(String uid) {
    state = state.whenData((list) => list.where((u) => u.uid != uid).toList());
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<List<MatchInfo>> matches(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final currentUser = authRepo.currentUser;
  if (currentUser == null) return [];

  final repo = ref.read(matchpointRepositoryProvider);
  final result = await repo.fetchMatches(currentUser.uid);

  return result.fold((failure) {
    AppLogger.error('Failed to fetch matches: ${failure.message}');
    throw failure.message;
  }, (matches) => matches);
}

@riverpod
Future<List<HashtagRanking>> hashtagRanking(Ref ref, int limit) async {
  final repo = ref.read(matchpointRepositoryProvider);
  final result = await repo.fetchHashtagRanking(limit: limit);

  return result.fold((failure) {
    AppLogger.error('Failed to fetch hashtag ranking: ${failure.message}');
    return [];
  }, (rankings) => rankings);
}

@riverpod
Future<List<HashtagRanking>> hashtagSearch(Ref ref, String query) async {
  if (query.length < 2) return [];

  final repo = ref.read(matchpointRepositoryProvider);
  final result = await repo.searchHashtags(query, limit: 20);

  return result.fold((failure) {
    AppLogger.error('Failed to search hashtags: ${failure.message}');
    return [];
  }, (rankings) => rankings);
}

@Riverpod(keepAlive: true)
class SwipeHistory extends _$SwipeHistory {
  static const _storageKeyPrefix = 'swipe_history_';
  static const _legacyStorageKey = 'swipe_history';
  static const _maxEntries = 200;

  @override
  List<SwipeHistoryEntry> build() {
    final authUser = ref.watch(authStateChangesProvider).value;
    if (authUser == null) {
      return [];
    }

    unawaited(_loadFromStorage(authUser.uid));
    return [];
  }

  String _storageKeyForUser(String userId) => '$_storageKeyPrefix$userId';

  Future<void> _loadFromStorage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr =
          prefs.getString(_storageKeyForUser(userId)) ??
          prefs.getString(_legacyStorageKey);
      if (jsonStr == null) return;

      final list = (jsonDecode(jsonStr) as List)
          .map((e) => SwipeHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      final seenTargets = <String>{};
      final normalized = list
          .where((item) => seenTargets.add(item.targetUserId))
          .toList();

      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;
      if (currentUserId != null && currentUserId != userId) return;

      state = normalized;
    } catch (e, st) {
      AppLogger.warning('Failed to load swipe history', e, st);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final userId = ref.read(authRepositoryProvider).currentUser?.uid;
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(state.map((e) => e.toJson()).toList());

      if (userId != null) {
        await prefs.setString(_storageKeyForUser(userId), jsonStr);
      }

      await prefs.setString(_legacyStorageKey, jsonStr);
    } catch (e, st) {
      AppLogger.warning('Failed to save swipe history', e, st);
    }
  }

  void addSwipe(AppUser user, String type) {
    final entry = SwipeHistoryEntry(
      targetUserId: user.uid,
      targetUserName: user.appDisplayName.isNotEmpty
          ? user.appDisplayName
          : (user.nome ?? 'Usuario'),
      targetUserPhoto: user.foto,
      action: type,
      timestamp: DateTime.now(),
    );

    final withoutSameUser = state
        .where((item) => item.targetUserId != user.uid)
        .toList();
    state = [entry, ...withoutSameUser].take(_maxEntries).toList();
    _saveToStorage();
  }

  void undoLast() {
    if (state.isNotEmpty) {
      state = state.sublist(1);
      _saveToStorage();
    }
  }
}
