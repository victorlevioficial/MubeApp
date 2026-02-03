import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'matchpoint_controller.g.dart';

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
      ref
          .read(analyticsServiceProvider)
          .logMatchPointFilter(instruments: [], genres: genres, distance: 0);
    }

    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }

  static bool _debugForceMatch = false;

  void debugSetForceMatch() {
    _debugForceMatch = true;
    AppLogger.info('🛠️ DEBUG: Next swipe will trigger a MATCH! (Static Mode)');
  }

  Future<AppUser?> swipeRight(AppUser targetUser) async {
    return await _handleSwipe(targetUser, 'like');
  }

  Future<void> swipeLeft(AppUser targetUser) async {
    await _handleSwipe(targetUser, 'dislike');
  }

  Future<AppUser?> _handleSwipe(AppUser targetUser, String type) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) return null;

    final repo = ref.read(matchpointRepositoryProvider);

    // DEBUG BYPASS
    if (type == 'like' && _debugForceMatch) {
      _debugForceMatch = false; // Reset
      // In a real forced scenario, we would also write to DB,
      // but for UI testing we just pretend it matched.
      // We still save the 'like' to DB so the card disappears from future queries
      await repo.saveInteraction(
        currentUserId: currentUser.uid,
        targetUserId: targetUser.uid,
        type: type,
      );
      AppLogger.info('🚀 FORCED MATCH TRIGGERED!');
      return targetUser;
    }

    final result = await repo.saveInteraction(
      currentUserId: currentUser.uid,
      targetUserId: targetUser.uid,
      type: type,
    );

    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return null;
      },
      (isMatch) async {
        if (isMatch) {
          AppLogger.info("IT'S A MATCH!");

          // Criar conversa automaticamente
          try {
            final appUserAsync = ref.read(currentUserProfileProvider);
            final appUser = appUserAsync.value;
            final myName =
                appUser?.nome ?? currentUser.displayName ?? 'Usuário';
            final myPhoto = appUser?.foto ?? currentUser.photoURL;

            final chatRepo = ref.read(chatRepositoryProvider);
            await chatRepo.getOrCreateConversation(
              myUid: currentUser.uid,
              otherUid: targetUser.uid,
              otherUserName: targetUser.nome ?? 'Usuário',
              otherUserPhoto: targetUser.foto,
              myName: myName,
              myPhoto: myPhoto,
              type: 'matchpoint',
            );
          } catch (e) {
            AppLogger.error('Erro ao criar conversa automática: $e');
          }

          return targetUser;
        }
        return null;
      },
    );
  }

  Future<void> unmatchUser(String targetUserId) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) return;

    final chatRepo = ref.read(chatRepositoryProvider);
    final matchRepo = ref.read(matchpointRepositoryProvider);

    // 1. Delete conversation (Calculate ID)
    final conversationId = chatRepo.getConversationId(
      currentUser.uid,
      targetUserId,
    );

    await chatRepo.deleteConversation(
      conversationId: conversationId,
      myUid: currentUser.uid,
      otherUid: targetUserId,
    );

    // 2. Set interaction to dislike
    await matchRepo.saveInteraction(
      currentUserId: currentUser.uid,
      targetUserId: targetUserId,
      type: 'dislike',
    );
    AppLogger.info('MatchpointController: Disliked $targetUserId');
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
