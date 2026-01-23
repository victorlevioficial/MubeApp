import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feed_item.dart';

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
    // Listen to favorites changes and sync isFavorited status
    // Listen to favorites changes logic REMOVED (Legacy Cleanup)
    // ref.listen<AsyncValue<Set<String>>>(likesControllerProvider, ...);

    return const FeedItemsState();
  }

  // Legacy sync methods removed (V8)

  /// Load items from a list (merges with existing items)
  void loadItems(List<FeedItem> newItems) {
    // Legacy sync logic removed
    // final favoritesState = ref.read(likesControllerProvider);
    // final favoriteIds = favoritesState.asData?.value ?? {};
    final updatedItems = Map<String, FeedItem>.from(state.items);

    for (final item in newItems) {
      updatedItems[item.uid] = item; // _reconcileItem(item, favoriteIds);
    }

    state = state.copyWith(items: updatedItems, isLoading: false);
  }

  /// Clear all items (used on refresh)
  void clearItems() {
    state = state.copyWith(items: {});
  }

  // Legacy status update methods removed (V8)

  /// Update a single item
  void updateItem(FeedItem item) {
    // Legacy sync logic removed
    // final favoritesState = ref.read(likesControllerProvider);
    // final favoriteIds = favoritesState.asData?.value ?? {};
    final updatedItems = Map<String, FeedItem>.from(state.items);
    // Apply reconciliation on update too
    updatedItems[item.uid] = item; // _reconcileItem(item, favoriteIds);
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
