import 'dart:async';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'matchpoint_controller.g.dart';

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

  const SwipeActionResult({
    required this.success,
    this.matchedUser,
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

  Future<SwipeActionResult> _handleSwipe(AppUser targetUser, String type) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) {
      AppLogger.error('Swipe bloqueado: usuário sem sessão FirebaseAuth');
      state = const AsyncError('Sessão expirada. Faça login novamente.', StackTrace.empty);
      return const SwipeActionResult(success: false);
    }

    try {
      final idToken = await currentUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        AppLogger.error('Swipe bloqueado: token FirebaseAuth ausente');
        state = const AsyncError('Sessão inválida. Faça login novamente.', StackTrace.empty);
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
          ref.read(likesQuotaProvider.notifier).updateRemaining(
            actionResult.remainingLikes!,
          );
        }

        if (actionResult.isMatch == true) {
          AppLogger.info("IT'S A MATCH!");

          // Invalidar provider de matches para recarregar
          ref.invalidate(matchesProvider);

          return SwipeActionResult(success: true, matchedUser: targetUser);
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
        ref.read(likesQuotaProvider.notifier).setQuota(
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

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

@riverpod
Future<List<AppUser>> matchpointCandidates(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final currentUser = authRepo.currentUser;

  if (currentUser == null) return [];

  // Get current user profile to know their genres
  final userProfile = await ref.watch(currentUserProfileProvider.future);
  if (userProfile == null) return [];

  final genres = List<String>.from(
    userProfile.matchpointProfile?[FirestoreFields.musicalGenres] ?? [],
  );
  if (genres.isEmpty) {
    AppLogger.warning('⚠️ MatchPoint: User has no genres.');
    return [];
  }
  AppLogger.info('🔍 MatchPoint Filters: Genres=$genres');

  final blockedUsers = userProfile.blockedUsers;

  final repo = ref.watch(matchpointRepositoryProvider);
  final result = await repo.fetchCandidates(
    currentUserId: currentUser.uid,
    genres: genres,
    blockedUsers: blockedUsers,
  );

  return result.fold(
    (l) {
      AppLogger.error('❌ MatchPoint Query Error: ${l.message}');
      throw l.message; // Throw string to show in UI
    },
    (r) {
      AppLogger.info(
        '✅ MatchPoint Query Success: Found ${r.length} candidates',
      );
      return r;
    },
  );
}

/// Provider para lista de matches do usuário
@riverpod
Future<List<MatchInfo>> matches(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final currentUser = authRepo.currentUser;

  if (currentUser == null) return [];

  final repo = ref.watch(matchpointRepositoryProvider);
  final result = await repo.fetchMatches(currentUser.uid);

  return result.fold(
    (failure) {
      AppLogger.error('Erro ao buscar matches: ${failure.message}');
      throw failure.message;
    },
    (matches) => matches,
  );
}

/// Provider para ranking de hashtags
@riverpod
Future<List<HashtagRanking>> hashtagRanking(Ref ref, int limit) async {
  final repo = ref.watch(matchpointRepositoryProvider);
  final result = await repo.fetchHashtagRanking(limit: limit);

  return result.fold(
    (failure) {
      AppLogger.error('Erro ao buscar ranking: ${failure.message}');
      return [];
    },
    (rankings) => rankings,
  );
}

/// Provider para busca de hashtags
@riverpod
Future<List<HashtagRanking>> hashtagSearch(
  Ref ref,
  String query,
) async {
  if (query.length < 2) return [];

  final repo = ref.watch(matchpointRepositoryProvider);
  final result = await repo.searchHashtags(query, limit: 20);

  return result.fold(
    (failure) {
      AppLogger.error('Erro ao buscar hashtags: ${failure.message}');
      return [];
    },
    (rankings) => rankings,
  );
}
