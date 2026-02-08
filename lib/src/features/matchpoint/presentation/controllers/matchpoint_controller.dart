import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart'; // ignore: unused_import
import 'package:mube/src/features/matchpoint/domain/match_info.dart'; // ignore: unused_import
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart'; // ignore: unused_import
import 'package:mube/src/features/matchpoint/domain/swipe_history_entry.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'matchpoint_controller.g.dart';

final matchpointSelectedTabNotifier = ValueNotifier<int>(0);

/// Estado do controller de quota de likes
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
  FutureOr<void> build() {
    // Initial state is void (idle)
  }

  Future<void> saveMatchpointProfile({
    required String intent,
    required List<String> genres,
    required List<String> hashtags,
    required bool isVisibleInHome,
  }) async {
    state = const AsyncLoading();

    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;

    if (currentUser == null) {
      state = const AsyncError('Usuário não autenticado', StackTrace.empty);
      return;
    }

    final appUserAsync = ref.read(currentUserProfileProvider);
    if (!appUserAsync.hasValue || appUserAsync.value == null) {
      state = const AsyncError('Perfil não carregado', StackTrace.empty);
      return;
    }

    final appUser = appUserAsync.value!;

    final Map<String, dynamic> updatedMatchpointProfile = {
      ...appUser.matchpointProfile ?? {},
      FirestoreFields.intent: intent,
      FirestoreFields.musicalGenres: genres,
      FirestoreFields.hashtags: hashtags,
      FirestoreFields.isActive: true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final Map<String, dynamic> updatedPrivacy = {
      ...appUser.privacySettings,
      'visible_in_home': isVisibleInHome,
    };

    final updatedUser = appUser.copyWith(
      matchpointProfile: updatedMatchpointProfile,
      privacySettings: updatedPrivacy,
    );

    final result = await authRepo.updateUser(updatedUser);

    if (result.isRight()) {
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logMatchPointFilter(instruments: [], genres: genres, distance: 0),
      );
    }

    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }

  Future<SwipeActionResult> swipeRight(AppUser targetUser) async {
    return await _handleSwipe(targetUser, 'like');
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
      AppLogger.error('Swipe bloqueado: usuário sem sessão FirebaseAuth');
      state = const AsyncError(
        'Sessão expirada. Faça login novamente.',
        StackTrace.empty,
      );
      return const SwipeActionResult(success: false);
    }

    try {
      final idToken = await currentUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        AppLogger.error('Swipe bloqueado: token FirebaseAuth ausente');
        state = const AsyncError(
          'Sessão inválida. Faça login novamente.',
          StackTrace.empty,
        );
        return const SwipeActionResult(success: false);
      }
    } catch (e) {
      AppLogger.error('Swipe bloqueado: erro ao obter token FirebaseAuth: $e');
      state = AsyncError('Erro de autenticação: $e', StackTrace.current);
      return const SwipeActionResult(success: false);
    }

    final repo = ref.read(matchpointRepositoryProvider);

    // Usar nova função submitAction que chama Cloud Function
    final result = await repo.submitAction(
      targetUserId: targetUser.uid,
      type: type,
    );

    return result.fold(
      (failure) {
        AppLogger.error('Falha ao processar swipe: ${failure.toString()}');
        state = AsyncError(failure.message, StackTrace.current);
        return const SwipeActionResult(success: false);
      },
      (actionResult) async {
        // Atualizar quota de likes no provider
        if (actionResult.remainingLikes != null) {
          ref
              .read(likesQuotaProvider.notifier)
              .updateRemaining(actionResult.remainingLikes!);
        }

        // Adicionar ao histórico local
        ref.read(swipeHistoryProvider.notifier).addSwipe(targetUser, type);

        if (actionResult.isMatch == true) {
          AppLogger.info("IT'S A MATCH!");

          // Invalidar provider de matches para recarregar
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

    // Dar dislike (que remove o match)
    final result = await repo.submitAction(
      targetUserId: targetUserId,
      type: 'dislike',
    );

    result.fold(
      (failure) {
        AppLogger.error('Erro ao dar unmatch: ${failure.message}');
      },
      (_) {
        AppLogger.info('MatchpointController: Unmatched $targetUserId');
        // Invalidar providers para recarregar
        ref.invalidate(matchesProvider);
      },
    );
  }

  /// Busca quota de likes restantes
  Future<void> fetchRemainingLikes() async {
    final repo = ref.read(matchpointRepositoryProvider);
    final result = await repo.getRemainingLikes();

    result.fold(
      (failure) {
        AppLogger.error('Erro ao buscar quota: ${failure.message}');
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

/// Provider para quota de likes
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

  /// Decrementa o contador otimisticamente (antes da resposta do backend)
  void decrementOptimistically() {
    if (state.remaining > 0) {
      state = state.copyWith(remaining: state.remaining - 1);
    }
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

/// Provider para lista de candidatos com estado mutável (UI otimista)
@Riverpod(keepAlive: true)
class MatchpointCandidates extends _$MatchpointCandidates {
  @override
  Future<List<AppUser>> build() async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;

    if (currentUser == null) return [];

    // Get current user profile ONCE (not reactively)
    final userProfile = await ref.read(currentUserProfileProvider.future);
    if (userProfile == null) return [];

    final genres = List<String>.from(
      userProfile.matchpointProfile?[FirestoreFields.musicalGenres] ?? [],
    );
    if (genres.isEmpty) {
      AppLogger.warning('⚠️ MatchPoint: User has no genres.');
      return [];
    }
    AppLogger.info('🔍 MatchPoint Filters: Genres=$genres');

    List<String> blockedFromCollection = const [];
    try {
      blockedFromCollection = await ref.read(blockedUsersProvider.future);
    } catch (_) {
      // Fallback para blocked_users caso stream falhe temporariamente
    }
    final blockedUsers = {
      ...userProfile.blockedUsers,
      ...blockedFromCollection,
    }.toList();

    final repo = ref.read(matchpointRepositoryProvider);
    final result = await repo.fetchCandidates(
      currentUserId: currentUser.uid,
      genres: genres,
      blockedUsers: blockedUsers,
    );

    return result.fold(
      (l) {
        AppLogger.error('❌ MatchPoint Query Error: ${l.message}');
        throw l.message;
      },
      (r) {
        AppLogger.info(
          '✅ MatchPoint Query Success: Found ${r.length} candidates',
        );
        return r;
      },
    );
  }

  /// Remove um candidato da lista local (UI otimista)
  void removeCandidate(String uid) {
    state = state.whenData((list) => list.where((u) => u.uid != uid).toList());
  }

  /// Recarrega a lista de candidatos do servidor
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Provider para lista de matches do usuário
@riverpod
Future<List<MatchInfo>> matches(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final currentUser = authRepo.currentUser;

  if (currentUser == null) return [];

  final repo = ref.read(matchpointRepositoryProvider);
  final result = await repo.fetchMatches(currentUser.uid);

  return result.fold((failure) {
    AppLogger.error('Erro ao buscar matches: ${failure.message}');
    throw failure.message;
  }, (matches) => matches);
}

/// Provider para ranking de hashtags
@riverpod
Future<List<HashtagRanking>> hashtagRanking(Ref ref, int limit) async {
  final repo = ref.read(matchpointRepositoryProvider);
  final result = await repo.fetchHashtagRanking(limit: limit);

  return result.fold((failure) {
    AppLogger.error('Erro ao buscar ranking: ${failure.message}');
    return [];
  }, (rankings) => rankings);
}

/// Provider para busca de hashtags
@riverpod
Future<List<HashtagRanking>> hashtagSearch(Ref ref, String query) async {
  if (query.length < 2) return [];

  final repo = ref.read(matchpointRepositoryProvider);
  final result = await repo.searchHashtags(query, limit: 20);

  return result.fold((failure) {
    AppLogger.error('Erro ao buscar hashtags: ${failure.message}');
    return [];
  }, (rankings) => rankings);
}

/// Provider para histórico de swipes — persistido em SharedPreferences
@Riverpod(keepAlive: true)
class SwipeHistory extends _$SwipeHistory {
  static const _storageKeyPrefix = 'swipe_history_';
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
      final jsonStr = prefs.getString(_storageKeyForUser(userId));
      if (jsonStr == null) return;

      final list = (jsonDecode(jsonStr) as List)
          .map((e) => SwipeHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;
      if (currentUserId != userId) return;

      state = list;
    } catch (_) {
      // Se falhar ao carregar, manter lista vazia
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final userId = ref.read(authRepositoryProvider).currentUser?.uid;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKeyForUser(userId), jsonStr);
    } catch (_) {
      // Falha silenciosa ao salvar
    }
  }

  void addSwipe(AppUser user, String type) {
    final entry = SwipeHistoryEntry(
      targetUserId: user.uid,
      targetUserName: user.nome ?? 'Usuário',
      targetUserPhoto: user.foto,
      action: type,
      timestamp: DateTime.now(),
    );

    state = [entry, ...state].take(_maxEntries).toList();
    _saveToStorage();
  }

  // Futuro: Implementar undo
  void undoLast() {
    if (state.isNotEmpty) {
      state = state.sublist(1);
      _saveToStorage();
    }
  }
}
