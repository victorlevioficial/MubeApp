import 'package:cloud_firestore/cloud_firestore.dart';
import 'feed_item.dart';

/// Represents a paginated response from the feed repository.
class PaginatedFeedResponse {
  /// List of feed items for this page.
  final List<FeedItem> items;

  /// The last document snapshot, used for pagination.
  /// Pass this to the next query as `startAfter` to get the next page.
  final DocumentSnapshot? lastDocument;

  /// Whether there are more items to load.
  final bool hasMore;

  const PaginatedFeedResponse({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  /// Creates an empty response (no items, no more pages).
  const PaginatedFeedResponse.empty()
    : items = const [],
      lastDocument = null,
      hasMore = false;
}
