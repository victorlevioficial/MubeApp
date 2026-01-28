import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/auth_repository.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';

part 'feed_view_controller.g.dart';

// State to hold both the data and the pagination metadata
class FeedListState {
  final List<FeedItem> items;
  final bool hasMore;
  final bool isLoadingMore;

  // Internal pagination state (not necessarily part of equality, but needed for logic)
  final List<FeedItem> _allSortedItems; // For location-based full-fetch
  final int _currentPage; // For location-based local pagination
  final DocumentSnapshot? _lastDocument; // For fetching more from Firestore

  const FeedListState({
    required this.items,
    this.hasMore = true,
    this.isLoadingMore = false,
    List<FeedItem>? allSortedItems,
    int currentPage = 0,
    DocumentSnapshot? lastDocument,
  }) : _allSortedItems = allSortedItems ?? const [],
       _currentPage = currentPage,
       _lastDocument = lastDocument;

  FeedListState copyWith({
    List<FeedItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
    List<FeedItem>? allSortedItems,
    int? currentPage,
    DocumentSnapshot? lastDocument,
  }) {
    return FeedListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      allSortedItems: allSortedItems ?? _allSortedItems,
      currentPage: currentPage ?? _currentPage,
      lastDocument: lastDocument ?? _lastDocument,
    );
  }
}

// The Controller
@riverpod
class FeedListController extends _$FeedListController {
  static const int _pageSize = 20;

  @override
  Future<FeedListState> build(FeedSectionType sectionType) async {
    // Initial load
    return _loadInitial(sectionType);
  }

  Future<FeedListState> _loadInitial(FeedSectionType sectionType) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      // Return empty if no user (should rely on auth redirect, but for safety)
      return const FeedListState(items: [], hasMore: false);
    }

    final feedRepo = ref.read(feedRepositoryProvider);
    final userLat = user.location?['lat'] as double?;
    final userLong = user.location?['lng'] as double?;
    final userGeohash = user.geohash;

    // DECISION: Use Location-Based (All Sorted) OR Classic Pagination
    if (userLat != null && userLong != null) {
      return _loadWithLocation(
        feedRepo,
        user.uid,
        userLat,
        userLong,
        userGeohash,
        sectionType,
      );
    } else {
      return _loadClassic(feedRepo, user.uid, userLat, userLong, sectionType);
    }
  }

  Future<FeedListState> _loadWithLocation(
    FeedRepository feedRepo,
    String userId,
    double lat,
    double long,
    String? geohash,
    FeedSectionType sectionType,
  ) async {
    String? filterType;
    String? category;
    String? excludeCategory;

    switch (sectionType) {
      case FeedSectionType.nearby:
        filterType = null;
        break;
      case FeedSectionType.artists:
        filterType = 'profissional';
        excludeCategory = 'Equipe Técnica';
        break;
      case FeedSectionType.technicians:
        filterType = 'profissional';
        category = 'Equipe Técnica';
        break;
      case FeedSectionType.bands:
        filterType = 'banda';
        break;
      case FeedSectionType.studios:
        filterType = 'estudio';
        break;
    }

    final result = await feedRepo.getAllUsersSortedByDistance(
      currentUserId: userId,
      userLat: lat,
      userLong: long,
      filterType: filterType,
      category: category,
      excludeCategory: excludeCategory,
      userGeohash: geohash,
    );

    return result.fold(
      (failure) => throw failure, // Riverpod handles errors
      (allSorted) {
        final initialPage = allSorted.take(_pageSize).toList();
        return FeedListState(
          items: initialPage,
          allSortedItems: allSorted,
          currentPage: 1,
          hasMore: allSorted.length > _pageSize,
        );
      },
    );
  }

  Future<FeedListState> _loadClassic(
    FeedRepository feedRepo,
    String userId,
    double? lat,
    double? long,
    FeedSectionType sectionType,
  ) async {
    if (sectionType == FeedSectionType.nearby) {
      // Cannot load nearby without location
      return const FeedListState(items: [], hasMore: false);
    }

    // Classic logic mapping
    // Note: reused logic from original screen _loadItemsClassicFallback
    // Simplified for brevity, handling specific calls logic

    // Ideally we'd have a unified repository method, but current repo has specific methods
    // We will use getUsersByTypePaginated for bands/studios, and explicit calls for others if needed

    // For Bands/Studios
    if (sectionType == FeedSectionType.bands ||
        sectionType == FeedSectionType.studios) {
      final type = sectionType == FeedSectionType.bands ? 'banda' : 'estudio';
      final result = await feedRepo.getUsersByTypePaginated(
        type: type,
        currentUserId: userId,
        userLat: lat,
        userLong: long,
        limit: _pageSize,
      );

      return result.fold(
        (failure) => throw failure,
        (response) => FeedListState(
          items: response.items,
          lastDocument: response.lastDocument,
          hasMore: response.hasMore,
        ),
      );
    }

    // For Artists/Technicians (Classic fallback was non-paginated in original code?
    // Wait, original code used getArtists/getTechnicians which return List<FeedItem> directly (no pagination struct exposed mostly)
    // Actually getArtists DOES fallback to getUsersByType (...)

    List<FeedItem> items = [];
    if (sectionType == FeedSectionType.artists) {
      final result = await feedRepo.getArtists(
        currentUserId: userId,
        userLat: lat,
        userLong: long,
        limit: _pageSize,
      );
      result.fold((l) => throw l, (r) => items = r);
    } else if (sectionType == FeedSectionType.technicians) {
      final result = await feedRepo.getTechnicians(
        currentUserId: userId,
        userLat: lat,
        userLong: long,
        limit: _pageSize,
      );
      result.fold((l) => throw l, (r) => items = r);
    }

    return FeedListState(
      items: items,
      hasMore:
          items.length >=
          _pageSize, // Approx guess since these APIs didn't return hasMore
    );
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    // Set loading more
    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      if (currentState._allSortedItems.isNotEmpty) {
        // Local Pagination
        final startIndex = currentState._currentPage * _pageSize;
        final endIndex = (startIndex + _pageSize).clamp(
          0,
          currentState._allSortedItems.length,
        );
        final nextItems = currentState._allSortedItems.sublist(
          startIndex,
          endIndex,
        );

        // Emulate delay? No need.
        state = AsyncData(
          currentState.copyWith(
            items: [...currentState.items, ...nextItems],
            currentPage: currentState._currentPage + 1,
            hasMore: endIndex < currentState._allSortedItems.length,
            isLoadingMore: false,
          ),
        );
      } else if (currentState._lastDocument != null) {
        // Remote Pagination
        final user = ref
            .read(currentUserProfileProvider)
            .value!; // Should exist if we loaded initial
        final feedRepo = ref.read(feedRepositoryProvider);

        String? type;
        if (sectionType == FeedSectionType.bands) type = 'banda';
        if (sectionType == FeedSectionType.studios) type = 'estudio';
        // Note: Artists/Technicians didn't implement proper remote pagination in original fallback,
        // so we only support it if we have types.
        // Logic from original _loadMore: "case bands, studios, artists (professional), technicians (professional)"
        if (sectionType == FeedSectionType.artists ||
            sectionType == FeedSectionType.technicians) {
          type = 'profissional';
        }

        if (type == null) {
          state = AsyncData(
            currentState.copyWith(isLoadingMore: false, hasMore: false),
          );
          return;
        }

        final result = await feedRepo.getUsersByTypePaginated(
          type: type,
          currentUserId: user.uid,
          userLat: user.location?['lat'],
          userLong: user.location?['lng'],
          limit: _pageSize,
          startAfter: currentState._lastDocument,
        );

        result.fold(
          (failure) {
            // On error during load more, we just stop loading.
            // Ideally we show toast via listener in UI.
            state = AsyncData(currentState.copyWith(isLoadingMore: false));
          },
          (response) {
            state = AsyncData(
              currentState.copyWith(
                items: [...currentState.items, ...response.items],
                lastDocument: response.lastDocument,
                hasMore: response.hasMore,
                isLoadingMore: false,
              ),
            );
          },
        );
      } else {
        // No pagination method available
        state = AsyncData(
          currentState.copyWith(isLoadingMore: false, hasMore: false),
        );
      }
    } catch (e) {
      // Revert loading state
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }
}
