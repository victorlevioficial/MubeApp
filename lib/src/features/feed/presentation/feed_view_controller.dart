import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/auth_repository.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../data/feed_repository.dart';
import '../domain/feed_discovery.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';

part 'feed_view_controller.g.dart';

class FeedListState {
  final List<FeedItem> items;
  final bool hasMore;
  final bool isLoadingMore;
  final List<FeedItem> _allSortedItems;
  final int _currentPage;

  const FeedListState({
    required this.items,
    this.hasMore = true,
    this.isLoadingMore = false,
    List<FeedItem>? allSortedItems,
    int currentPage = 0,
  }) : _allSortedItems = allSortedItems ?? const [],
       _currentPage = currentPage;

  FeedListState copyWith({
    List<FeedItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
    List<FeedItem>? allSortedItems,
    int? currentPage,
  }) {
    return FeedListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      allSortedItems: allSortedItems ?? _allSortedItems,
      currentPage: currentPage ?? _currentPage,
    );
  }
}

@riverpod
class FeedListController extends _$FeedListController {
  static const int _pageSize = 20;

  @override
  Future<FeedListState> build(FeedSectionType sectionType) async {
    return _loadInitial(sectionType);
  }

  Future<FeedListState> _loadInitial(FeedSectionType sectionType) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      return const FeedListState(items: [], hasMore: false);
    }

    final blockedIds = await _resolveBlockedIds(user.blockedUsers);
    final feedRepo = ref.read(feedRepositoryProvider);
    final filter = _mapSectionType(sectionType);

    final result = await feedRepo.getDiscoverFeedPoolSorted(
      currentUserId: user.uid,
      userLat: (user.location?['lat'] as num?)?.toDouble(),
      userLong: (user.location?['lng'] as num?)?.toDouble(),
      excludedIds: blockedIds,
      filter: filter,
    );

    return result.fold((failure) => throw failure, (allSortedItems) {
      final initialPage = allSortedItems.take(_pageSize).toList();
      return FeedListState(
        items: initialPage,
        allSortedItems: allSortedItems,
        currentPage: 1,
        hasMore: allSortedItems.length > _pageSize,
      );
    });
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      final startIndex = currentState._currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(
        0,
        currentState._allSortedItems.length,
      );
      final nextItems = currentState._allSortedItems.sublist(
        startIndex,
        endIndex,
      );

      state = AsyncData(
        currentState.copyWith(
          items: [...currentState.items, ...nextItems],
          currentPage: currentState._currentPage + 1,
          hasMore: endIndex < currentState._allSortedItems.length,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<List<String>> _resolveBlockedIds(List<String> directBlockedIds) async {
    final blocked = <String>{...directBlockedIds};
    try {
      final streamed = await ref.read(blockedUsersProvider.future);
      blocked.addAll(streamed);
    } catch (_) {
      // Use whatever is already locally available.
      final current = ref.read(blockedUsersProvider).value;
      if (current != null) blocked.addAll(current);
    }
    return blocked.toList(growable: false);
  }

  FeedDiscoveryFilter _mapSectionType(FeedSectionType sectionType) {
    switch (sectionType) {
      case FeedSectionType.nearby:
        return FeedDiscoveryFilter.all;
      case FeedSectionType.artists:
        return FeedDiscoveryFilter.artists;
      case FeedSectionType.bands:
        return FeedDiscoveryFilter.bands;
      case FeedSectionType.technicians:
        return FeedDiscoveryFilter.technicians;
      case FeedSectionType.studios:
        return FeedDiscoveryFilter.studios;
    }
  }
}
