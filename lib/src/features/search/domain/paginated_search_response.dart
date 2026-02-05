import 'package:cloud_firestore/cloud_firestore.dart';

import '../../feed/domain/feed_item.dart';

/// Represents a paginated response from the search repository.
class PaginatedSearchResponse {
  /// List of search results for this page.
  final List<FeedItem> items;

  /// The last document snapshot, used for pagination.
  final DocumentSnapshot? lastDocument;

  /// Whether there are more items to load.
  final bool hasMore;

  const PaginatedSearchResponse({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  /// Creates an empty response (no items, no more pages).
  const PaginatedSearchResponse.empty()
    : items = const [],
      lastDocument = null,
      hasMore = false;
}
