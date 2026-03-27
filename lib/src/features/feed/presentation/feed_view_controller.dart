import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/firestore_constants.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../data/feed_repository.dart';
import '../domain/feed_discovery.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import '../domain/paginated_feed_response.dart';

part 'feed_view_controller.g.dart';

class FeedListState {
  final List<FeedItem> items;
  final bool hasMore;
  final bool isLoadingMore;
  final int _currentPage;

  const FeedListState({
    required this.items,
    this.hasMore = true,
    this.isLoadingMore = false,
    int currentPage = 0,
  }) : _currentPage = currentPage;

  FeedListState copyWith({
    List<FeedItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
  }) {
    return FeedListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? _currentPage,
    );
  }
}

@riverpod
class FeedListController extends _$FeedListController {
  static const int _pageSize = 20;
  FeedRepository? _feedRepository;
  AuthRepository? _authRepository;
  AppUser? _currentUser;
  final Map<FeedSectionType, DocumentSnapshot?> _sectionLastDocuments = {};

  @override
  Future<FeedListState> build(FeedSectionType sectionType) async {
    ref.keepAlive();
    _feedRepository ??= ref.read(feedRepositoryProvider);
    _authRepository ??= ref.read(authRepositoryProvider);
    return _loadInitial(sectionType);
  }

  Future<FeedListState> _loadInitial(FeedSectionType sectionType) async {
    final user = await _resolveCurrentUserProfile();
    if (user == null) {
      return const FeedListState(items: [], hasMore: false);
    }

    final blockedIds = await _resolveBlockedIds(user.blockedUsers);
    final page = await _fetchSectionPage(
      sectionType,
      currentUserId: user.uid,
      blockedIds: blockedIds,
      userLat: (user.location?['lat'] as num?)?.toDouble(),
      userLong: (user.location?['lng'] as num?)?.toDouble(),
      pageIndex: 0,
    );

    return FeedListState(
      items: page.items,
      hasMore: page.hasMore,
      currentPage: page.items.isEmpty ? 0 : 1,
    );
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
      final user = await _resolveCurrentUserProfile();
      if (user == null) {
        state = AsyncData(
          currentState.copyWith(isLoadingMore: false, hasMore: false),
        );
        return;
      }

      final blockedIds = await _resolveBlockedIds(user.blockedUsers);
      final page = await _fetchSectionPage(
        sectionType,
        currentUserId: user.uid,
        blockedIds: blockedIds,
        userLat: (user.location?['lat'] as num?)?.toDouble(),
        userLong: (user.location?['lng'] as num?)?.toDouble(),
        pageIndex: currentState._currentPage,
      );

      state = AsyncData(
        _sortMergedState(
          currentState.copyWith(
            items: _mergeUniqueItems(currentState.items, page.items),
            currentPage: currentState._currentPage + 1,
            hasMore: page.hasMore,
            isLoadingMore: false,
          ),
        ),
      );
    } catch (_) {
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<PaginatedFeedResponse> _fetchSectionPage(
    FeedSectionType sectionType, {
    required String currentUserId,
    required List<String> blockedIds,
    required double? userLat,
    required double? userLong,
    required int pageIndex,
  }) async {
    final feedRepo = _feedRepository!;

    switch (sectionType) {
      case FeedSectionType.bands:
        return _fetchTypePaginatedPage(
          sectionType: sectionType,
          type: ProfileType.band,
          currentUserId: currentUserId,
          blockedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          pageIndex: pageIndex,
        );
      case FeedSectionType.studios:
        return _fetchTypePaginatedPage(
          sectionType: sectionType,
          type: ProfileType.studio,
          currentUserId: currentUserId,
          blockedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          pageIndex: pageIndex,
        );
      case FeedSectionType.venues:
        return _fetchPublicContractorsPaginatedPage(
          sectionType: sectionType,
          currentUserId: currentUserId,
          blockedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          pageIndex: pageIndex,
        );
      case FeedSectionType.technicians:
        return _fetchTechniciansPaginatedPage(
          sectionType: sectionType,
          currentUserId: currentUserId,
          blockedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          pageIndex: pageIndex,
        );
      case FeedSectionType.artists:
        final result = await feedRepo.getArtists(
          currentUserId: currentUserId,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: _pageSize,
        );
        return result.fold(
          (failure) => throw failure,
          (items) => PaginatedFeedResponse(
            items: items.take(_pageSize).toList(growable: false),
            hasMore: false,
          ),
        );
      case FeedSectionType.nearby:
        if (userLat == null || userLong == null) {
          return const PaginatedFeedResponse.empty();
        }
        final result = await feedRepo.getNearbyUsersOptimized(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          excludedIds: blockedIds,
          targetResults: _pageSize,
        );
        return result.fold(
          (failure) => throw failure,
          (items) => PaginatedFeedResponse(
            items: items.take(_pageSize).toList(growable: false),
            hasMore: false,
          ),
        );
    }
  }

  Future<PaginatedFeedResponse> _fetchTypePaginatedPage({
    required FeedSectionType sectionType,
    required String type,
    required String currentUserId,
    required List<String> blockedIds,
    required double? userLat,
    required double? userLong,
    required int pageIndex,
  }) async {
    if (pageIndex == 0) {
      _sectionLastDocuments.remove(sectionType);
    }

    final startAfter = pageIndex == 0
        ? null
        : _sectionLastDocuments[sectionType];
    if (pageIndex > 0 && startAfter == null) {
      return const PaginatedFeedResponse.empty();
    }

    final result = await _feedRepository!.getUsersByTypePaginated(
      type: type,
      currentUserId: currentUserId,
      excludedIds: blockedIds,
      userLat: userLat,
      userLong: userLong,
      limit: _pageSize,
      startAfter: startAfter,
    );

    return result.fold((failure) => throw failure, (page) {
      _sectionLastDocuments[sectionType] = page.lastDocument;
      return page;
    });
  }

  Future<PaginatedFeedResponse> _fetchPublicContractorsPaginatedPage({
    required FeedSectionType sectionType,
    required String currentUserId,
    required List<String> blockedIds,
    required double? userLat,
    required double? userLong,
    required int pageIndex,
  }) async {
    if (pageIndex == 0) {
      _sectionLastDocuments.remove(sectionType);
    }

    final startAfter = pageIndex == 0
        ? null
        : _sectionLastDocuments[sectionType];
    if (pageIndex > 0 && startAfter == null) {
      return const PaginatedFeedResponse.empty();
    }

    final result = await _feedRepository!.getPublicContractorsPaginated(
      currentUserId: currentUserId,
      excludedIds: blockedIds,
      userLat: userLat,
      userLong: userLong,
      limit: _pageSize,
      startAfter: startAfter,
    );

    return result.fold((failure) => throw failure, (page) {
      _sectionLastDocuments[sectionType] = page.lastDocument;
      return page;
    });
  }

  Future<PaginatedFeedResponse> _fetchTechniciansPaginatedPage({
    required FeedSectionType sectionType,
    required String currentUserId,
    required List<String> blockedIds,
    required double? userLat,
    required double? userLong,
    required int pageIndex,
  }) async {
    if (pageIndex == 0) {
      _sectionLastDocuments.remove(sectionType);
    }

    final startAfter = pageIndex == 0
        ? null
        : _sectionLastDocuments[sectionType];
    if (pageIndex > 0 && startAfter == null) {
      return const PaginatedFeedResponse.empty();
    }

    final result = await _feedRepository!.getTechniciansPaginated(
      currentUserId: currentUserId,
      excludedIds: blockedIds,
      userLat: userLat,
      userLong: userLong,
      limit: _pageSize,
      startAfter: startAfter,
    );

    return result.fold((failure) => throw failure, (page) {
      _sectionLastDocuments[sectionType] = page.lastDocument;
      return page;
    });
  }

  List<FeedItem> _mergeUniqueItems(
    List<FeedItem> existingItems,
    List<FeedItem> incomingItems,
  ) {
    final merged = <FeedItem>[];
    final seenIds = <String>{};
    for (final item in existingItems) {
      if (seenIds.add(item.uid)) {
        merged.add(item);
      }
    }
    for (final item in incomingItems) {
      if (seenIds.add(item.uid)) {
        merged.add(item);
      }
    }
    return merged;
  }

  FeedListState _sortMergedState(FeedListState state) {
    final sortedItems = [...state.items]..sort(FeedDiscovery.compareByDistance);
    return state.copyWith(items: sortedItems);
  }

  Future<AppUser?> _resolveCurrentUserProfile() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final immediate = ref.read(currentUserProfileProvider).value;
    if (immediate != null) {
      _currentUser = immediate;
      return immediate;
    }

    if (_authRepository?.currentUser == null) {
      return null;
    }

    try {
      final profile = await ref
          .read(currentUserProfileProvider.future)
          .timeout(const Duration(seconds: 2));
      if (!ref.mounted) return null;
      _currentUser = profile;
      return profile;
    } catch (_) {
      if (!ref.mounted) return null;
      return _currentUser ?? ref.read(currentUserProfileProvider).value;
    }
  }

  Future<List<String>> _resolveBlockedIds(List<String> directBlockedIds) async {
    final blocked = <String>{...directBlockedIds};

    if (!ref.mounted) {
      return blocked.toList(growable: false);
    }

    final blockedState = ref.read(blockedUsersProvider);
    final immediate = blockedState.value;
    if (immediate != null) {
      blocked.addAll(immediate);
      return blocked.toList(growable: false);
    }

    if (blockedState.isLoading) {
      try {
        final streamed = await ref
            .read(blockedUsersProvider.future)
            .timeout(const Duration(milliseconds: 350));
        if (!ref.mounted) {
          return blocked.toList(growable: false);
        }
        blocked.addAll(streamed);
      } catch (_) {
        if (!ref.mounted) {
          return blocked.toList(growable: false);
        }
        final current = ref.read(blockedUsersProvider).value;
        if (current != null) {
          blocked.addAll(current);
        }
      }
    }

    return blocked.toList(growable: false);
  }
}
