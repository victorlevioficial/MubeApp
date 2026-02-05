import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a paginated response for favorites.
class PaginatedFavoritesResponse {
  /// Favorite user IDs ordered by favorited date (desc).
  final List<String> favoriteIds;

  /// The last document snapshot, used for pagination.
  final DocumentSnapshot? lastDocument;

  /// Whether there are more items to load.
  final bool hasMore;

  const PaginatedFavoritesResponse({
    required this.favoriteIds,
    this.lastDocument,
    required this.hasMore,
  });

  /// Creates an empty response (no items, no more pages).
  const PaginatedFavoritesResponse.empty()
    : favoriteIds = const [],
      lastDocument = null,
      hasMore = false;
}
