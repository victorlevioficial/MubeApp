import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
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

    final updatedUser = appUser.copyWith(
      matchpointProfile: updatedMatchpointProfile,
    );

    final result = await authRepo.updateUser(updatedUser);

    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }

  static bool _debugForceMatch = false;

  void debugSetForceMatch() {
    _debugForceMatch = true;
    print('🛠️ DEBUG: Next swipe will trigger a MATCH! (Static Mode)');
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
      print('🚀 FORCED MATCH TRIGGERED!');
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
      (isMatch) {
        if (isMatch) {
          print("IT'S A MATCH!");
          return targetUser;
        }
        return null;
      },
    );
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
    print('⚠️ MatchPoint: User has no genres.');
    return [];
  }
  print('🔍 MatchPoint Filters: Genres=$genres');

  final repo = ref.watch(matchpointRepositoryProvider);
  final result = await repo.fetchCandidates(
    currentUserId: currentUser.uid,
    genres: genres,
  );

  return result.fold(
    (l) {
      print('❌ MatchPoint Query Error: ${l.message}');
      throw l.message; // Throw string to show in UI
    },
    (r) {
      print('✅ MatchPoint Query Success: Found ${r.length} candidates');
      return r;
    },
  );
}
