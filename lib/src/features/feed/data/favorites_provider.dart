import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Notifier for managing favorites with local cache + Firebase sync
class FavoritesNotifier extends Notifier<FavoritesState> {
  static const String _favoritesKey = 'user_favorites';

  @override
  FavoritesState build() {
    // CRITICAL: Load from cache FIRST - immediate
    _loadFromCache();

    // Sync with Firebase in BACKGROUND
    _initializeFromFirebase();

    return const FavoritesState();
  }

  /// Load favorites from local cache (SharedPreferences)
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(_favoritesKey) ?? [];

      if (cached.isNotEmpty) {
        // CRITICAL: Update state immediately with cache
        state = state.copyWith(favoriteIds: cached.toSet());
      }
    } catch (e) {
      // Silent fail - cache is optional
      print('Error loading favorites from cache: $e');
    }
  }

  /// Save favorites to local cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, state.favoriteIds.toList());
    } catch (e) {
      // Silent fail - cache is optional
      print('Error saving favorites to cache: $e');
    }
  }

  /// Initialize favorites from Firebase (background sync)
  Future<void> _initializeFromFirebase() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    try {
      final feedRepository = ref.read(feedRepositoryProvider);
      final favorites = await feedRepository.getUserFavorites(user.uid);

      // Update state AND cache
      state = state.copyWith(
        favoriteIds: favorites,
        isLoading: false,
        error: null,
      );

      await _saveToCache();
    } catch (e) {
      // KEEP cache if Firebase fails - offline support
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar favoritos: $e',
      );
    }
  }

  /// Toggle favorite status with optimistic update + cache persistence
  Future<bool> toggleFavorite(String targetId) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return false;

    final wasFavorited = state.isFavorited(targetId);

    // Optimistic update for favorites set
    final newFavorites = Set<String>.from(state.favoriteIds);
    if (wasFavorited) {
      newFavorites.remove(targetId);
    } else {
      newFavorites.add(targetId);
    }

    // Update state IMMEDIATELY
    state = state.copyWith(favoriteIds: newFavorites);

    // Always save to cache - ensures persistence
    await _saveToCache();

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
      await _saveToCache();

      return isFavorited;
    } catch (e) {
      // Revert on error but keep cache updated
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
      await _saveToCache();

      return wasFavorited;
    }
  }

  /// Add a favorite (used for external updates)
  void addFavorite(String itemId) {
    final newFavorites = Set<String>.from(state.favoriteIds)..add(itemId);
    state = state.copyWith(favoriteIds: newFavorites);
    _saveToCache(); // Always save
  }

  /// Remove a favorite (used for external updates)
  void removeFavorite(String itemId) {
    final newFavorites = Set<String>.from(state.favoriteIds)..remove(itemId);
    state = state.copyWith(favoriteIds: newFavorites);
    _saveToCache(); // Always save
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh favorites from server
  Future<void> refresh() async {
    await _initializeFromFirebase();
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
