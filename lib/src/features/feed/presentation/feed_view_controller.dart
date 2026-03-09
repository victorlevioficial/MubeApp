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
  final DocumentSnapshot? _lastDocument;
  final int _currentPage;

  const FeedListState({
    required this.items,
    this.hasMore = true,
    this.isLoadingMore = false,
    DocumentSnapshot? lastDocument,
    int currentPage = 0,
  }) : _lastDocument = lastDocument,
       _currentPage = currentPage;

  FeedListState copyWith({
    List<FeedItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
    int? currentPage,
    bool clearLastDocument = false,
  }) {
    return FeedListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: clearLastDocument ? null : (lastDocument ?? _lastDocument),
      currentPage: currentPage ?? _currentPage,
    );
  }
}

@riverpod
class FeedListController extends _$FeedListController {
  static const int _pageSize = 20;
  static const int _maxTechnicianPageScans = 4;
  FeedRepository? _feedRepository;
  AuthRepository? _authRepository;
  AppUser? _currentUser;

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
      startAfter: null,
    );

    return FeedListState(
      items: page.items,
      hasMore: page.hasMore,
      lastDocument: page.lastDocument,
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
          currentState.copyWith(
            isLoadingMore: false,
            hasMore: false,
            clearLastDocument: true,
          ),
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
        startAfter: currentState._lastDocument,
      );

      state = AsyncData(
        currentState.copyWith(
          items: _mergeUniqueItems(currentState.items, page.items),
          currentPage: currentState._currentPage + 1,
          lastDocument: page.lastDocument,
          hasMore: page.hasMore,
          isLoadingMore: false,
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
    required DocumentSnapshot? startAfter,
  }) async {
    final feedRepo = _feedRepository!;

    switch (sectionType) {
      case FeedSectionType.bands:
        final result = await feedRepo.getUsersByTypePaginated(
          type: ProfileType.band,
          currentUserId: currentUserId,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: _pageSize,
          startAfter: startAfter,
        );
        return result.fold((failure) => throw failure, (response) => response);
      case FeedSectionType.studios:
        final result = await feedRepo.getUsersByTypePaginated(
          type: ProfileType.studio,
          currentUserId: currentUserId,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: _pageSize,
          startAfter: startAfter,
        );
        return result.fold((failure) => throw failure, (response) => response);
      case FeedSectionType.technicians:
        return _fetchTechniciansPage(
          currentUserId: currentUserId,
          blockedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          startAfter: startAfter,
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

  Future<PaginatedFeedResponse> _fetchTechniciansPage({
    required String currentUserId,
    required List<String> blockedIds,
    required double? userLat,
    required double? userLong,
    required DocumentSnapshot? startAfter,
  }) async {
    final feedRepo = _feedRepository!;
    final technicians = <FeedItem>[];
    final seenIds = <String>{};
    var cursor = startAfter;
    var hasMore = true;
    var scanCount = 0;

    while (technicians.length < _pageSize &&
        hasMore &&
        scanCount < _maxTechnicianPageScans) {
      scanCount++;
      final result = await feedRepo.getUsersByTypePaginated(
        type: ProfileType.professional,
        currentUserId: currentUserId,
        excludedIds: blockedIds,
        userLat: userLat,
        userLong: userLong,
        limit: _pageSize,
        startAfter: cursor,
      );
      final response = result.fold((failure) => throw failure, (data) => data);
      cursor = response.lastDocument;
      hasMore = response.hasMore;

      for (final item in response.items) {
        if (!FeedDiscovery.isPureTechnician(item)) continue;
        if (seenIds.add(item.uid)) {
          technicians.add(item);
          if (technicians.length >= _pageSize) {
            break;
          }
        }
      }
    }

    return PaginatedFeedResponse(
      items: technicians,
      lastDocument: cursor,
      hasMore: hasMore,
    );
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
