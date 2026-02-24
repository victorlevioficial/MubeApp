import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/mixins/pagination_mixin.dart';
import '../../../core/utils/rate_limiter.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../feed/data/feed_repository.dart';
import '../../feed/domain/feed_item.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../data/search_repository.dart';
import '../domain/search_filters.dart';

/// Search pagination state.
@immutable
class SearchPaginationState extends PaginationState<FeedItem> {
  /// Current search filters.
  final SearchFilters filters;

  /// User latitude used for proximity sorting.
  final double? userLat;

  /// User longitude used for proximity sorting.
  final double? userLng;

  const SearchPaginationState({
    this.filters = const SearchFilters(),
    this.userLat,
    this.userLng,
    super.items = const [],
    super.status = PaginationStatus.initial,
    super.errorMessage,
    super.lastDocument,
    super.hasMore = true,
    super.currentPage = 0,
    super.pageSize = 20,
  });

  SearchPaginationState copyWithSearch({
    SearchFilters? filters,
    double? userLat,
    double? userLng,
    List<FeedItem>? items,
    PaginationStatus? status,
    String? errorMessage,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    int? currentPage,
    int? pageSize,
    bool clearError = false,
    bool clearLastDocument = false,
  }) {
    return SearchPaginationState(
      filters: filters ?? this.filters,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchPaginationState &&
        other.filters == filters &&
        other.userLat == userLat &&
        other.userLng == userLng &&
        listEquals(other.items, items) &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.lastDocument == lastDocument &&
        other.hasMore == hasMore &&
        other.currentPage == currentPage &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
    filters,
    userLat,
    userLng,
    items,
    status,
    errorMessage,
    lastDocument,
    hasMore,
    currentPage,
    pageSize,
  );
}

/// Search controller using unified pagination state.
class SearchController extends Notifier<SearchPaginationState> {
  Timer? _debounceTimer;
  int _currentRequestId = 0;
  final RateLimiter _rateLimiter = RateLimitConfigs.search;

  // Local snapshot used when search runs with Home-compatible distance pipeline.
  final List<FeedItem> _homeDistanceSnapshot = [];
  bool _useHomeDistancePagination = false;

  @override
  SearchPaginationState build() {
    final user = ref.read(currentUserProfileProvider).value;
    final lat = (user?.location?['lat'] as num?)?.toDouble();
    final lng = (user?.location?['lng'] as num?)?.toDouble();

    // Keep location in sync and refresh results if profile changed.
    ref.listen(currentUserProfileProvider, (prev, next) {
      if (!next.hasValue) return;

      final nextUser = next.value;
      final nextLat = (nextUser?.location?['lat'] as num?)?.toDouble();
      final nextLng = (nextUser?.location?['lng'] as num?)?.toDouble();

      if (nextLat != null &&
          nextLng != null &&
          (nextLat != state.userLat || nextLng != state.userLng)) {
        _updateState(state.copyWithSearch(userLat: nextLat, userLng: nextLng));
      }

      if (next.value != prev?.value) {
        _performSearch();
      }
    });

    ref.listen(blockedUsersProvider, (prev, next) {
      if (prev != next) {
        _performSearch();
      }
    });

    Future.microtask(_performSearch);

    return SearchPaginationState(userLat: lat, userLng: lng);
  }

  void _updateState(SearchPaginationState newState) {
    state = newState;
  }

  void setTerm(String term) {
    _updateState(
      state.copyWithSearch(filters: state.filters.copyWith(term: term)),
    );
    _debouncedSearch();
  }

  void setCategory(SearchCategory category) {
    _updateState(
      state.copyWithSearch(
        filters: state.filters.copyWith(
          category: category,
          professionalSubcategory: null,
        ),
      ),
    );
    _performSearch();
  }

  void setProfessionalSubcategory(ProfessionalSubcategory? subcategory) {
    _updateState(
      state.copyWithSearch(
        filters: state.filters.copyWith(professionalSubcategory: subcategory),
      ),
    );
    _performSearch();
  }

  void setGenres(List<String> genres) {
    _updateState(
      state.copyWithSearch(filters: state.filters.copyWith(genres: genres)),
    );
    _performSearch();
  }

  void setInstruments(List<String> instruments) {
    _updateState(
      state.copyWithSearch(
        filters: state.filters.copyWith(instruments: instruments),
      ),
    );
    _performSearch();
  }

  void setRoles(List<String> roles) {
    _updateState(
      state.copyWithSearch(filters: state.filters.copyWith(roles: roles)),
    );
    _performSearch();
  }

  void setServices(List<String> services) {
    _updateState(
      state.copyWithSearch(filters: state.filters.copyWith(services: services)),
    );
    _performSearch();
  }

  void setStudioType(String? type) {
    _updateState(
      state.copyWithSearch(filters: state.filters.copyWith(studioType: type)),
    );
    _performSearch();
  }

  void setBackingVocalFilter(bool? canDoBacking) {
    _updateState(
      state.copyWithSearch(
        filters: state.filters.copyWith(canDoBackingVocal: canDoBacking),
      ),
    );
    _performSearch();
  }

  void clearFilters() {
    _updateState(state.copyWithSearch(filters: state.filters.clearFilters()));
    _performSearch();
  }

  void reset() {
    _updateState(
      state.copyWithSearch(
        filters: const SearchFilters(),
        clearError: true,
        clearLastDocument: true,
      ),
    );
    _performSearch();
  }

  Future<void> refresh() async {
    await _performSearch();
  }

  Future<void> loadMore() async {
    if (!canLoadMore) return;

    if (_useHomeDistancePagination) {
      await _loadMoreFromHomeDistanceSnapshot();
      return;
    }

    final requestId = ++_currentRequestId;

    _updateState(
      state.copyWithSearch(
        status: PaginationStatus.loadingMore,
        clearError: true,
      ),
    );

    try {
      final user = ref.read(currentUserProfileProvider).value;
      final blockedUsers = await _resolveBlockedUsers(user);
      final userLat =
          (user?.location?['lat'] as num?)?.toDouble() ?? state.userLat;
      final userLng =
          (user?.location?['lng'] as num?)?.toDouble() ?? state.userLng;

      if (userLat != null &&
          userLng != null &&
          (userLat != state.userLat || userLng != state.userLng)) {
        _updateState(state.copyWithSearch(userLat: userLat, userLng: userLng));
      }

      final repository = ref.read(searchRepositoryProvider);
      final result = await repository.searchUsers(
        filters: state.filters,
        startAfter: state.lastDocument,
        requestId: requestId,
        getCurrentRequestId: () => _currentRequestId,
        blockedUsers: blockedUsers,
      );

      if (_currentRequestId != requestId) return;

      result.fold(
        (failure) {
          if (_currentRequestId != requestId) return;
          _updateState(
            state.copyWithSearch(
              status: PaginationStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
        (response) {
          if (_currentRequestId != requestId) return;

          final sortedResults = SearchRepository.sortByProximity(
            response.items,
            userLat,
            userLng,
          );

          final existingIds = state.items.map((item) => item.uid).toSet();
          final newItems = sortedResults
              .where((item) => !existingIds.contains(item.uid))
              .toList();

          // Re-sort globally to keep one proximity ranking across pages.
          final allItems = SearchRepository.sortByProximity(
            [...state.items, ...newItems],
            userLat,
            userLng,
          );

          final hasMore = response.hasMore;

          _updateState(
            state.copyWithSearch(
              items: allItems,
              status: hasMore
                  ? PaginationStatus.loaded
                  : PaginationStatus.noMoreData,
              hasMore: hasMore,
              currentPage: state.currentPage + 1,
              lastDocument: response.lastDocument,
            ),
          );
        },
      );
    } catch (e) {
      if (_currentRequestId != requestId) return;
      _updateState(
        state.copyWithSearch(
          status: PaginationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _debouncedSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), _performSearch);
  }

  Future<void> _performSearch() async {
    final requestId = ++_currentRequestId;
    final user = ref.read(currentUserProfileProvider).value;
    final blockedUsers = await _resolveBlockedUsers(user);
    final userId = user?.uid ?? 'anonymous';
    final userLat =
        (user?.location?['lat'] as num?)?.toDouble() ?? state.userLat;
    final userLng =
        (user?.location?['lng'] as num?)?.toDouble() ?? state.userLng;

    if (userLat != null &&
        userLng != null &&
        (userLat != state.userLat || userLng != state.userLng)) {
      _updateState(state.copyWithSearch(userLat: userLat, userLng: userLng));
    }

    if (!_rateLimiter.allowRequest(userId)) {
      final timeUntil = _rateLimiter.timeUntilNextRequest(userId);
      debugPrint('[Search] Rate limit exceeded. Try again in $timeUntil');
      _updateState(
        state.copyWithSearch(
          status: PaginationStatus.error,
          errorMessage: 'Muitas buscas. Tente novamente em alguns segundos.',
        ),
      );
      return;
    }

    _updateState(
      state.copyWithSearch(
        status: PaginationStatus.loading,
        hasMore: true,
        clearError: true,
        clearLastDocument: true,
      ),
    );

    try {
      _homeDistanceSnapshot.clear();
      _useHomeDistancePagination = false;

      if (_canUseHomeDistancePipeline(
        filters: state.filters,
        userLat: userLat,
        userLng: userLng,
      )) {
        final result = await ref
            .read(feedRepositoryProvider)
            .getNearbyUsersOptimized(
              currentUserId: user!.uid,
              userLat: userLat!,
              userLong: userLng!,
              filterType: _mapCategoryToProfileType(state.filters.category),
              excludedIds: blockedUsers,
              targetResults: SearchConfig.batchSize,
            );

        if (_currentRequestId != requestId) return;

        result.fold(
          (failure) {
            if (_currentRequestId != requestId) return;
            _updateState(
              state.copyWithSearch(
                status: PaginationStatus.error,
                errorMessage: failure.message,
              ),
            );
          },
          (items) {
            if (_currentRequestId != requestId) return;

            _useHomeDistancePagination = true;
            _homeDistanceSnapshot.addAll(items);

            final firstPage = items.take(state.pageSize).toList();
            final hasMore = items.length > firstPage.length;

            _updateState(
              state.copyWithSearch(
                items: firstPage,
                status: hasMore
                    ? PaginationStatus.loaded
                    : PaginationStatus.noMoreData,
                hasMore: hasMore,
                currentPage: firstPage.isEmpty ? 0 : 1,
                clearLastDocument: true,
              ),
            );
          },
        );
        return;
      }

      final repository = ref.read(searchRepositoryProvider);
      final result = await repository.searchUsers(
        filters: state.filters,
        startAfter: null,
        requestId: requestId,
        getCurrentRequestId: () => _currentRequestId,
        blockedUsers: blockedUsers,
      );

      if (_currentRequestId != requestId) return;

      result.fold(
        (failure) {
          if (_currentRequestId != requestId) return;
          debugPrint('[Search] Error: $failure');
          _updateState(
            state.copyWithSearch(
              status: PaginationStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
        (response) {
          if (_currentRequestId != requestId) return;

          final sortedResults = SearchRepository.sortByProximity(
            response.items,
            userLat,
            userLng,
          );

          final hasMore = response.hasMore;

          _updateState(
            state.copyWithSearch(
              items: sortedResults,
              status: hasMore
                  ? PaginationStatus.loaded
                  : PaginationStatus.noMoreData,
              hasMore: hasMore,
              currentPage: 1,
              lastDocument: response.lastDocument,
            ),
          );
        },
      );
    } catch (e) {
      if (_currentRequestId != requestId) return;
      debugPrint('[Search] Error: $e');
      _updateState(
        state.copyWithSearch(
          status: PaginationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _loadMoreFromHomeDistanceSnapshot() async {
    final currentState = state;

    _updateState(
      currentState.copyWithSearch(
        status: PaginationStatus.loadingMore,
        clearError: true,
      ),
    );

    final startIndex = currentState.currentPage * currentState.pageSize;
    if (startIndex >= _homeDistanceSnapshot.length) {
      _updateState(
        currentState.copyWithSearch(
          status: PaginationStatus.noMoreData,
          hasMore: false,
          clearLastDocument: true,
        ),
      );
      return;
    }

    final endIndex = (startIndex + currentState.pageSize).clamp(
      0,
      _homeDistanceSnapshot.length,
    );

    final nextItems = _homeDistanceSnapshot.sublist(startIndex, endIndex);
    final allItems = [...currentState.items, ...nextItems];
    final hasMore = endIndex < _homeDistanceSnapshot.length;

    _updateState(
      currentState.copyWithSearch(
        items: allItems,
        status: hasMore ? PaginationStatus.loaded : PaginationStatus.noMoreData,
        hasMore: hasMore,
        currentPage: currentState.currentPage + 1,
        clearLastDocument: true,
      ),
    );
  }

  bool _canUseHomeDistancePipeline({
    required SearchFilters filters,
    required double? userLat,
    required double? userLng,
  }) {
    // Disabled for now to avoid hard caps from local snapshots and ensure
    // full Firestore pagination in Search.
    if (userLat == null || userLng == null) return false;
    if (filters.hasActiveFilters) return false;
    return false;
  }

  String? _mapCategoryToProfileType(SearchCategory category) {
    switch (category) {
      case SearchCategory.professionals:
        return ProfileType.professional;
      case SearchCategory.bands:
        return ProfileType.band;
      case SearchCategory.studios:
        return ProfileType.studio;
      case SearchCategory.all:
        return null;
    }
  }

  bool get canLoadMore {
    return state.hasMore &&
        !state.isLoading &&
        state.status != PaginationStatus.error;
  }

  bool get isLoadingMore => state.isLoadingMore;

  AsyncValue<List<FeedItem>> get resultsAsyncValue => state.toAsyncValue();

  void cancelDebounce() {
    _debounceTimer?.cancel();
  }

  Future<List<String>> _resolveBlockedUsers(
    AppUser? user, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final blocked = <String>{};
    if (user != null) {
      blocked.addAll(user.blockedUsers);
    }

    final blockedState = ref.read(blockedUsersProvider);
    final immediate = blockedState.value;
    if (immediate != null) {
      blocked.addAll(immediate);
    } else if (blockedState.isLoading) {
      try {
        final streamed = await ref
            .read(blockedUsersProvider.future)
            .timeout(timeout);
        blocked.addAll(streamed);
      } catch (_) {
        // fallback com dados já disponíveis
      }
    }

    return blocked.toList();
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchPaginationState>(() {
      return SearchController();
    });
