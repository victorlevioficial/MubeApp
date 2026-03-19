import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/error_message_resolver.dart';
import '../../../core/mixins/pagination_mixin.dart';
import '../../../core/utils/rate_limiter.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../feed/data/feed_repository.dart';
import '../../feed/domain/feed_item.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../data/search_repository.dart';
import '../domain/search_filters.dart';

const Object _unsetSearchLocation = Object();

/// Search pagination state.
@immutable
class SearchPaginationState extends PaginationState<FeedItem> {
  /// Current search filters.
  final SearchFilters filters;

  /// Filters effectively used by the current result set.
  final SearchFilters effectiveFilters;

  /// User latitude used for proximity sorting.
  final double? userLat;

  /// User longitude used for proximity sorting.
  final double? userLng;

  const SearchPaginationState({
    this.filters = const SearchFilters(),
    this.effectiveFilters = const SearchFilters(),
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
    SearchFilters? effectiveFilters,
    Object? userLat = _unsetSearchLocation,
    Object? userLng = _unsetSearchLocation,
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
      effectiveFilters: effectiveFilters ?? this.effectiveFilters,
      userLat: identical(userLat, _unsetSearchLocation)
          ? this.userLat
          : userLat as double?,
      userLng: identical(userLng, _unsetSearchLocation)
          ? this.userLng
          : userLng as double?,
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

  bool get isShowingRelaxedResults => effectiveFilters != filters;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchPaginationState &&
        other.filters == filters &&
        other.effectiveFilters == effectiveFilters &&
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
    effectiveFilters,
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
  bool _mounted = true;

  @override
  SearchPaginationState build() {
    ref.onDispose(() {
      _mounted = false;
      _currentRequestId++;
      _debounceTimer?.cancel();
    });
    final user = ref.read(currentUserProfileProvider).value;
    final lat = (user?.location?['lat'] as num?)?.toDouble();
    final lng = (user?.location?['lng'] as num?)?.toDouble();

    // Refresh search only when the search context itself changes.
    ref.listen(currentUserProfileProvider, (prev, next) {
      final previousUser = prev?.value;
      final nextUser = next.value;
      if (_didSearchContextChange(previousUser, nextUser) &&
          _shouldRunSearch(state.filters)) {
        unawaited(_performSearch());
      }
    });

    ref.listen(blockedUsersProvider, (prev, next) {
      if (prev != next && _shouldRunSearch(state.filters)) {
        unawaited(_performSearch());
      }
    });

    return SearchPaginationState(userLat: lat, userLng: lng);
  }

  void _updateState(SearchPaginationState newState) {
    state = newState;
  }

  double? _userLat(AppUser? user) =>
      (user?.location?['lat'] as num?)?.toDouble();

  double? _userLng(AppUser? user) =>
      (user?.location?['lng'] as num?)?.toDouble();

  bool _didSearchContextChange(AppUser? previousUser, AppUser? nextUser) {
    if (previousUser?.uid != nextUser?.uid) return true;
    if (_userLat(previousUser) != _userLat(nextUser)) return true;
    if (_userLng(previousUser) != _userLng(nextUser)) return true;

    final previousBlocked = (previousUser?.blockedUsers ?? const <String>[])
        .toSet();
    final nextBlocked = (nextUser?.blockedUsers ?? const <String>[]).toSet();
    return !setEquals(previousBlocked, nextBlocked);
  }

  bool _shouldRunSearch(SearchFilters filters) {
    return filters.term.trim().isNotEmpty ||
        filters.hasActiveFilters ||
        filters.category != SearchCategory.all;
  }

  void _setFilters(SearchFilters filters, {bool debounced = false}) {
    final nextFilters = filters.sanitizedForSearch();
    final shouldRunSearch = _shouldRunSearch(nextFilters);
    _updateState(
      state.copyWithSearch(
        filters: nextFilters,
        effectiveFilters: nextFilters,
        items: shouldRunSearch ? state.items : const [],
        status: shouldRunSearch ? state.status : PaginationStatus.initial,
        hasMore: shouldRunSearch ? state.hasMore : false,
        currentPage: shouldRunSearch ? state.currentPage : 0,
        clearError: true,
        clearLastDocument: !shouldRunSearch,
      ),
    );

    if (!shouldRunSearch) {
      _debounceTimer?.cancel();
      _homeDistanceSnapshot.clear();
      _useHomeDistancePagination = false;
      return;
    }

    if (debounced) {
      _debouncedSearch();
      return;
    }

    _performSearch();
  }

  SearchFilters _ensureProfessionalCompatibleFilters(SearchFilters filters) {
    if (filters.category == SearchCategory.bands ||
        filters.category == SearchCategory.studios) {
      return filters.sanitizeForCategory(SearchCategory.professionals);
    }
    return filters;
  }

  SearchFilters _ensureStudioCompatibleFilters(SearchFilters filters) {
    if (filters.category == SearchCategory.bands ||
        filters.category == SearchCategory.professionals) {
      return filters.sanitizeForCategory(SearchCategory.studios);
    }
    return filters;
  }

  void setTerm(String term) {
    _setFilters(state.filters.copyWith(term: term), debounced: true);
  }

  void setCategory(SearchCategory category) {
    _setFilters(state.filters.sanitizeForCategory(category));
  }

  void setProfessionalSubcategory(ProfessionalSubcategory? subcategory) {
    final baseFilters = subcategory == null
        ? state.filters
        : _ensureProfessionalCompatibleFilters(state.filters);
    _setFilters(baseFilters.sanitizeForProfessionalSubcategory(subcategory));
  }

  void setGenres(List<String> genres) {
    _setFilters(state.filters.copyWith(genres: genres));
  }

  void setInstruments(List<String> instruments) {
    final baseFilters = instruments.isEmpty
        ? state.filters
        : _ensureProfessionalCompatibleFilters(state.filters);
    _setFilters(baseFilters.copyWith(instruments: instruments));
  }

  void setRoles(List<String> roles) {
    final baseFilters = roles.isEmpty
        ? state.filters
        : _ensureProfessionalCompatibleFilters(state.filters);
    _setFilters(baseFilters.copyWith(roles: roles));
  }

  void setOffersRemoteRecording(bool? offersRemoteRecording) {
    final baseFilters = offersRemoteRecording == null
        ? state.filters
        : _ensureProfessionalCompatibleFilters(state.filters);
    _setFilters(
      baseFilters.copyWith(offersRemoteRecording: offersRemoteRecording),
    );
  }

  void setServices(List<String> services) {
    final baseFilters = services.isEmpty
        ? state.filters
        : _ensureStudioCompatibleFilters(state.filters);
    _setFilters(baseFilters.copyWith(services: services));
  }

  void setStudioType(String? type) {
    final baseFilters = type == null
        ? state.filters
        : _ensureStudioCompatibleFilters(state.filters);
    _setFilters(baseFilters.copyWith(studioType: type));
  }

  void setBackingVocalFilter(bool? canDoBacking) {
    final baseFilters = canDoBacking == null
        ? state.filters
        : _ensureProfessionalCompatibleFilters(state.filters);
    _setFilters(baseFilters.copyWith(canDoBackingVocal: canDoBacking));
  }

  void applyFilters(SearchFilters filters) {
    _setFilters(filters);
  }

  void clearFilters() {
    _setFilters(state.filters.clearFilters());
  }

  void reset() {
    _setFilters(const SearchFilters());
  }

  Future<void> refresh() async {
    if (!_shouldRunSearch(state.filters)) return;
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
        filters: state.effectiveFilters,
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
    } catch (e, stack) {
      if (_currentRequestId != requestId) return;
      AppLogger.error('Unexpected search pagination error', e, stack);
      _updateState(
        state.copyWithSearch(
          status: PaginationStatus.error,
          errorMessage: resolveErrorMessage(e),
        ),
      );
    }
  }

  Future<List<String>> _resolveBlockedUsers(AppUser? user) async {
    final localBlocked = user?.blockedUsers ?? [];
    try {
      final remoteBlocked = ref.read(blockedUsersProvider).value ?? <String>[];
      return {...localBlocked, ...remoteBlocked}.toList();
    } catch (_) {
      return localBlocked;
    }
  }

  void _debouncedSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), _performSearch);
  }

  Future<void> _performSearch() async {
    final requestId = ++_currentRequestId;
    final requestedFilters = state.filters.sanitizedForSearch();
    if (!_shouldRunSearch(requestedFilters)) {
      _debounceTimer?.cancel();
      _homeDistanceSnapshot.clear();
      _useHomeDistancePagination = false;
      _updateState(
        state.copyWithSearch(
          filters: requestedFilters,
          effectiveFilters: requestedFilters,
          items: const [],
          status: PaginationStatus.initial,
          hasMore: false,
          currentPage: 0,
          clearError: true,
          clearLastDocument: true,
        ),
      );
      return;
    }
    final user = ref.read(currentUserProfileProvider).value;
    final blockedUsers = await _resolveBlockedUsers(user);

    if (!_mounted) return;

    final userId = user?.uid ?? 'anonymous';
    final userLat = _userLat(user);
    final userLng = _userLng(user);

    if (userLat != state.userLat || userLng != state.userLng) {
      _updateState(state.copyWithSearch(userLat: userLat, userLng: userLng));
    }

    if (requestedFilters.hasConflictingTypeFilters) {
      _updateState(
        state.copyWithSearch(
          filters: requestedFilters,
          effectiveFilters: requestedFilters,
          items: const [],
          status: PaginationStatus.noMoreData,
          hasMore: false,
          currentPage: 0,
          clearError: true,
          clearLastDocument: true,
        ),
      );
      return;
    }

    if (!_rateLimiter.allowRequest(userId)) {
      final timeUntil = _rateLimiter.timeUntilNextRequest(userId);
      AppLogger.warning(
        'Search rate limit exceeded for $userId. Retry in $timeUntil.',
      );
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
        filters: requestedFilters,
        effectiveFilters: requestedFilters,
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
        filters: requestedFilters,
        userLat: userLat,
        userLng: userLng,
      )) {
        final result = await ref
            .read(feedRepositoryProvider)
            .getNearbyUsersOptimized(
              currentUserId: user!.uid,
              userLat: userLat!,
              userLong: userLng!,
              filterType: _mapCategoryToProfileType(requestedFilters.category),
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
                effectiveFilters: requestedFilters,
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
        filters: requestedFilters,
        startAfter: null,
        requestId: requestId,
        getCurrentRequestId: () => _currentRequestId,
        blockedUsers: blockedUsers,
      );

      if (_currentRequestId != requestId) return;

      if (result.isLeft()) {
        if (_currentRequestId != requestId) return;
        final failure = result.getLeft().toNullable()!;
        AppLogger.warning('Search request failed', failure);
        _updateState(
          state.copyWithSearch(
            status: PaginationStatus.error,
            errorMessage: failure.message,
          ),
        );
        return;
      }

      if (_currentRequestId != requestId) return;

      final response = result.getRight().toNullable()!;
      var items = response.items;
      var lastDoc = response.lastDocument;
      var hasMore = response.hasMore;
      var effectiveFilters = requestedFilters;

      // ── Soft-filter fallback ──
      // If we got zero results and have specific filters,
      // retry with relaxed filters to show approximate matches.
      if (items.isEmpty && SearchRepository.canRelaxFilters(requestedFilters)) {
        final relaxed = SearchRepository.relaxFilters(requestedFilters);
        final fallback = await repository.searchUsers(
          filters: relaxed,
          startAfter: null,
          requestId: requestId,
          getCurrentRequestId: () => _currentRequestId,
          blockedUsers: blockedUsers,
        );

        if (_currentRequestId != requestId) return;

        fallback.fold(
          (_) {}, // ignore fallback errors
          (fallbackResp) {
            if (fallbackResp.items.isNotEmpty) {
              items = fallbackResp.items;
              lastDoc = fallbackResp.lastDocument;
              hasMore = fallbackResp.hasMore;
              effectiveFilters = relaxed;
            }
          },
        );
      }

      final sortedResults = SearchRepository.sortByProximity(
        items,
        userLat,
        userLng,
      );

      _updateState(
        state.copyWithSearch(
          effectiveFilters: effectiveFilters,
          items: sortedResults,
          status: hasMore
              ? PaginationStatus.loaded
              : PaginationStatus.noMoreData,
          hasMore: hasMore,
          currentPage: 1,
          lastDocument: lastDoc,
        ),
      );
    } catch (e, stack) {
      if (_currentRequestId != requestId) return;
      AppLogger.error('Unexpected search controller error', e, stack);
      _updateState(
        state.copyWithSearch(
          status: PaginationStatus.error,
          errorMessage: resolveErrorMessage(e),
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
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchPaginationState>(() {
      return SearchController();
    });
