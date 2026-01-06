import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import 'feed_repository.dart';

/// State for favorites management
class FavoritesState {
  final Set<String> favoriteIds;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.favoriteIds = const {},
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    Set<String>? favoriteIds,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isFavorited(String itemId) => favoriteIds.contains(itemId);
}

/// Notifier for managing favorites with Firebase integration
class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() {
    // Auto-initialize when user is available
    ref.listen(currentUserProfileProvider, (previous, next) {
      if (next.value != null && previous?.value?.uid != next.value?.uid) {
        initialize();
      }
    });

    return const FavoritesState();
  }

  /// Initialize favorites for the current user
  Future<void> initialize() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final feedRepository = ref.read(feedRepositoryProvider);
      final favorites = await feedRepository.getUserFavorites(user.uid);
      state = state.copyWith(
        favoriteIds: favorites,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar favoritos: $e',
      );
    }
  }

  /// Toggle favorite status for an item with optimistic update
  Future<bool> toggleFavorite(String targetId) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return false;

    final wasFavorited = state.isFavorited(targetId);

    // Optimistic update
    final newFavorites = Set<String>.from(state.favoriteIds);
    if (wasFavorited) {
      newFavorites.remove(targetId);
    } else {
      newFavorites.add(targetId);
    }
    state = state.copyWith(favoriteIds: newFavorites);

    try {
      final feedRepository = ref.read(feedRepositoryProvider);
      final isFavorited = await feedRepository.toggleFavorite(
        userId: user.uid,
        targetId: targetId,
      );

      // Confirm the state matches server response
      final confirmedFavorites = Set<String>.from(state.favoriteIds);
      if (isFavorited && !confirmedFavorites.contains(targetId)) {
        confirmedFavorites.add(targetId);
      } else if (!isFavorited && confirmedFavorites.contains(targetId)) {
        confirmedFavorites.remove(targetId);
      }

      state = state.copyWith(favoriteIds: confirmedFavorites, error: null);

      return isFavorited;
    } catch (e) {
      // Revert on error
      final revertedFavorites = Set<String>.from(state.favoriteIds);
      if (wasFavorited) {
        revertedFavorites.add(targetId);
      } else {
        revertedFavorites.remove(targetId);
      }

      state = state.copyWith(
        favoriteIds: revertedFavorites,
        error: 'Erro ao favoritar: $e',
      );

      return wasFavorited;
    }
  }

  /// Add a favorite (used for external updates)
  void addFavorite(String itemId) {
    final newFavorites = Set<String>.from(state.favoriteIds)..add(itemId);
    state = state.copyWith(favoriteIds: newFavorites);
  }

  /// Remove a favorite (used for external updates)
  void removeFavorite(String itemId) {
    final newFavorites = Set<String>.from(state.favoriteIds)..remove(itemId);
    state = state.copyWith(favoriteIds: newFavorites);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh favorites from server
  Future<void> refresh() async {
    await initialize();
  }
}

/// Provider for favorites management
final favoritesProvider = NotifierProvider<FavoritesNotifier, FavoritesState>(
  FavoritesNotifier.new,
);

/// Convenience provider to check if an item is favorited
final isFavoritedProvider = Provider.family<bool, String>((ref, itemId) {
  final state = ref.watch(favoritesProvider);
  return state.isFavorited(itemId);
});

/// Provider for favorite count
final favoritesCountProvider = Provider<int>((ref) {
  final state = ref.watch(favoritesProvider);
  return state.favoriteIds.length;
});
