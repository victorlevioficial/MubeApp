import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/data/auth_repository.dart';
import 'feed_items_provider.dart';
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

/// Notifier with CACHE-FIRST approach - cache is the absolute truth
class FavoritesNotifier extends Notifier<FavoritesState> {
  String _cacheKey(String userId) => 'favorites_$userId';

  @override
  FavoritesState build() {
    // Load from cache immediately - this is the source of truth
    _loadFromCache();
    // Sync to Firebase in background (fire and forget)
    _syncToFirebase();
    return const FavoritesState();
  }

  /// Load from cache - this is the ONLY source of truth for UI
  Future<void> _loadFromCache() async {
    try {
      final user = ref.read(currentUserProfileProvider).value;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(_cacheKey(user.uid)) ?? [];

      state = state.copyWith(favoriteIds: cached.toSet(), isLoading: false);
    } catch (e) {
      print('Error loading favorites cache: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Save to cache - immediate and synchronous
  Future<void> _saveToCache(Set<String> favorites) async {
    try {
      final user = ref.read(currentUserProfileProvider).value;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_cacheKey(user.uid), favorites.toList());
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  /// Sync to Firebase in background - never overwrites cache
  Future<void> _syncToFirebase() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    try {
      final feedRepository = ref.read(feedRepositoryProvider);

      // Get Firebase favorites
      final firebaseFavorites = await feedRepository.getUserFavorites(user.uid);

      // Merge with cache (cache wins on conflicts)
      final merged = Set<String>.from(state.favoriteIds)
        ..addAll(firebaseFavorites);

      // Only update if we found NEW favorites in Firebase
      if (merged.length > state.favoriteIds.length) {
        state = state.copyWith(favoriteIds: merged);
        await _saveToCache(merged);
      }
    } catch (e) {
      print('Firebase sync failed (non-fatal): $e');
      // Don't update state - cache is truth
    }
  }

  /// Toggle favorite - cache first, Firebase second
  Future<bool> toggleFavorite(String targetId) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return false;

    final wasFavorited = state.isFavorited(targetId);
    final newFavorites = Set<String>.from(state.favoriteIds);

    // 1. Update cache FIRST
    if (wasFavorited) {
      newFavorites.remove(targetId);
    } else {
      newFavorites.add(targetId);
    }

    // 2. Update state immediately
    state = state.copyWith(favoriteIds: newFavorites);

    // 3. Save to cache immediately
    await _saveToCache(newFavorites);

    // 4. Update feed_items_provider counter for real-time UI
    try {
      ref
          .read(feedItemsProvider.notifier)
          .updateItemFavoriteStatus(
            targetId,
            isFavorited: !wasFavorited,
            incrementCount: wasFavorited ? -1 : 1,
          );
    } catch (e) {
      print('Error updating feed item counter: $e');
    }

    // 5. Sync to Firebase in background (fire and forget)
    _syncSingleToFirebase(targetId, !wasFavorited, user.uid);

    return !wasFavorited;
  }

  /// Sync single item to Firebase - background only
  Future<void> _syncSingleToFirebase(
    String targetId,
    bool shouldFavorite,
    String userId,
  ) async {
    try {
      final feedRepository = ref.read(feedRepositoryProvider);
      await feedRepository.toggleFavorite(userId: userId, targetId: targetId);
    } catch (e) {
      print('Firebase sync failed (non-fatal): $e');
      // Don't revert - cache is truth
    }
  }

  /// Add favorite (cache first)
  void addFavorite(String itemId) {
    final newFavorites = Set<String>.from(state.favoriteIds)..add(itemId);
    state = state.copyWith(favoriteIds: newFavorites);
    _saveToCache(newFavorites);
  }

  /// Remove favorite (cache first)
  void removeFavorite(String itemId) {
    final newFavorites = Set<String>.from(state.favoriteIds)..remove(itemId);
    state = state.copyWith(favoriteIds: newFavorites);
    _saveToCache(newFavorites);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Force refresh from cache (never from Firebase)
  Future<void> refresh() async {
    await _loadFromCache();
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
