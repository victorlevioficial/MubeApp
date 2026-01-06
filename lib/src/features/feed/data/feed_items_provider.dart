import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feed_item.dart';
import 'favorites_provider.dart';

/// State for centralized feed items management
class FeedItemsState {
  final Map<String, FeedItem> items;
  final bool isLoading;
  final String? error;

  const FeedItemsState({
    this.items = const {},
    this.isLoading = false,
    this.error,
  });

  FeedItemsState copyWith({
    Map<String, FeedItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return FeedItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get a specific item by uid
  FeedItem? getItem(String uid) => items[uid];

  /// Get all items as a list
  List<FeedItem> get itemsList => items.values.toList();
}

/// Notifier for centralized feed items state management
class FeedItemsNotifier extends Notifier<FeedItemsState> {
  @override
  FeedItemsState build() {
    // Listen to favorites changes and sync isFavorited status
    ref.listen(favoritesProvider, (previous, next) {
      // Sync when favoriteIds change
      if (previous?.favoriteIds != next.favoriteIds) {
        _syncFavoritesStatus(next.favoriteIds);
      }

      // Also sync when loading completes (hot reload case)
      if (previous?.isLoading == true && next.isLoading == false) {
        _syncFavoritesStatusWithoutCountChange(next.favoriteIds);
      }
    });

    return const FeedItemsState();
  }

  /// Sync isFavorited status for all items based on favorites set
  /// Also updates favoriteCount when status changes
  void _syncFavoritesStatus(Set<String> favoriteIds) {
    if (state.items.isEmpty) return;

    final updatedItems = <String, FeedItem>{};
    for (final entry in state.items.entries) {
      final shouldBeFavorited = favoriteIds.contains(entry.key);
      final wasFavorited = entry.value.isFavorited;

      if (wasFavorited != shouldBeFavorited) {
        // Status changed - update both isFavorited and favoriteCount
        final countDelta = shouldBeFavorited ? 1 : -1;
        updatedItems[entry.key] = entry.value.copyWith(
          isFavorited: shouldBeFavorited,
          favoriteCount: (entry.value.favoriteCount + countDelta).clamp(
            0,
            999999,
          ),
        );
      } else {
        updatedItems[entry.key] = entry.value;
      }
    }

    state = state.copyWith(items: updatedItems);
  }

  /// Sync isFavorited status WITHOUT changing favoriteCount
  /// Used after hot reload when data comes from Firestore
  void _syncFavoritesStatusWithoutCountChange(Set<String> favoriteIds) {
    if (state.items.isEmpty) return;

    final updatedItems = <String, FeedItem>{};
    for (final entry in state.items.entries) {
      final shouldBeFavorited = favoriteIds.contains(entry.key);

      if (entry.value.isFavorited != shouldBeFavorited) {
        // Only update isFavorited, keep favoriteCount from Firestore
        updatedItems[entry.key] = entry.value.copyWith(
          isFavorited: shouldBeFavorited,
        );
      } else {
        updatedItems[entry.key] = entry.value;
      }
    }

    state = state.copyWith(items: updatedItems);
  }

  /// Load items from a list (merges with existing items)
  void loadItems(List<FeedItem> newItems) {
    final favoriteIds = ref.read(favoritesProvider).favoriteIds;
    final updatedItems = Map<String, FeedItem>.from(state.items);

    for (final item in newItems) {
      // Set isFavorited based on current favorites
      updatedItems[item.uid] = item.copyWith(
        isFavorited: favoriteIds.contains(item.uid),
      );
    }

    state = state.copyWith(items: updatedItems, isLoading: false);
  }

  /// Clear all items (used on refresh)
  void clearItems() {
    state = state.copyWith(items: {});
  }

  /// Update favorite status for a specific item (optimistic update)
  void updateItemFavoriteStatus(
    String uid, {
    required bool isFavorited,
    required int incrementCount,
  }) {
    final item = state.items[uid];
    if (item == null) return;

    final updatedItem = item.copyWith(
      isFavorited: isFavorited,
      favoriteCount: (item.favoriteCount + incrementCount).clamp(0, 999999),
    );

    final updatedItems = Map<String, FeedItem>.from(state.items);
    updatedItems[uid] = updatedItem;

    state = state.copyWith(items: updatedItems);
  }

  /// Revert favorite status (used on error)
  void revertItemFavoriteStatus(
    String uid, {
    required bool wasFavorited,
    required int revertCount,
  }) {
    updateItemFavoriteStatus(
      uid,
      isFavorited: wasFavorited,
      incrementCount: revertCount,
    );
  }

  /// Update a single item
  void updateItem(FeedItem item) {
    final favoriteIds = ref.read(favoritesProvider).favoriteIds;
    final updatedItems = Map<String, FeedItem>.from(state.items);
    updatedItems[item.uid] = item.copyWith(
      isFavorited: favoriteIds.contains(item.uid),
    );
    state = state.copyWith(items: updatedItems);
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set error
  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

/// Main provider for feed items state
final feedItemsProvider = NotifierProvider<FeedItemsNotifier, FeedItemsState>(
  FeedItemsNotifier.new,
);

/// Provider for individual item (reactive with select)
final feedItemProvider = Provider.family<FeedItem?, String>((ref, uid) {
  return ref.watch(feedItemsProvider.select((state) => state.items[uid]));
});

/// Provider for item's isFavorited status only (super granular rebuilds)
final feedItemIsFavoritedProvider = Provider.family<bool, String>((ref, uid) {
  return ref.watch(
    feedItemsProvider.select((state) => state.items[uid]?.isFavorited ?? false),
  );
});

/// Provider for item's favoriteCount only
final feedItemFavoriteCountProvider = Provider.family<int, String>((ref, uid) {
  return ref.watch(
    feedItemsProvider.select((state) => state.items[uid]?.favoriteCount ?? 0),
  );
});
