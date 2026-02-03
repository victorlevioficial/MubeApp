import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../feed/domain/feed_item.dart';
import '../data/search_repository.dart';
import '../domain/search_filters.dart';

/// Search screen UI state
class SearchState {
  final SearchFilters filters;
  final AsyncValue<List<FeedItem>> results;
  final bool isLoadingMore;
  final bool hasMore;
  final double? userLat;
  final double? userLng;

  const SearchState({
    this.filters = const SearchFilters(),
    this.results = const AsyncValue.loading(),
    this.isLoadingMore = false,
    this.hasMore = true,
    this.userLat,
    this.userLng,
  });

  SearchState copyWith({
    SearchFilters? filters,
    AsyncValue<List<FeedItem>>? results,
    bool? isLoadingMore,
    bool? hasMore,
    double? userLat,
    double? userLng,
  }) {
    return SearchState(
      filters: filters ?? this.filters,
      results: results ?? this.results,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
    );
  }
}

/// Controller for the search screen using Riverpod 3.x Notifier pattern
class SearchController extends Notifier<SearchState> {
  Timer? _debounceTimer;
  int _currentRequestId = 0;

  @override
  SearchState build() {
    // Get user's location from their profile (registered address)
    final userAsync = ref.watch(currentUserProfileProvider);

    // Extract location from user profile
    double? lat;
    double? lng;
    userAsync.whenData((user) {
      if (user?.location != null) {
        lat = (user!.location!['lat'] as num?)?.toDouble();
        lng = (user.location!['lng'] as num?)?.toDouble();
      }
    });

    // Initialize search when we have location
    Future.microtask(() {
      state = state.copyWith(userLat: lat, userLng: lng);
      _performSearch();
    });

    return SearchState(userLat: lat, userLng: lng);
  }

  /// Update search term with debounce
  void setTerm(String term) {
    state = state.copyWith(filters: state.filters.copyWith(term: term));
    _debouncedSearch();
  }

  /// Update category filter
  void setCategory(SearchCategory category) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        category: category,
        // Clear subcategory when changing main category
        professionalSubcategory: null,
      ),
    );
    _performSearch();
  }

  /// Update professional subcategory
  void setProfessionalSubcategory(ProfessionalSubcategory? subcategory) {
    state = state.copyWith(
      filters: state.filters.copyWith(professionalSubcategory: subcategory),
    );
    _performSearch();
  }

  /// Update genre filter
  void setGenres(List<String> genres) {
    state = state.copyWith(filters: state.filters.copyWith(genres: genres));
    _performSearch();
  }

  /// Update instruments filter
  void setInstruments(List<String> instruments) {
    state = state.copyWith(
      filters: state.filters.copyWith(instruments: instruments),
    );
    _performSearch();
  }

  /// Update crew roles filter
  void setRoles(List<String> roles) {
    state = state.copyWith(filters: state.filters.copyWith(roles: roles));
    _performSearch();
  }

  /// Update studio services filter
  void setServices(List<String> services) {
    state = state.copyWith(filters: state.filters.copyWith(services: services));
    _performSearch();
  }

  /// Update studio type filter
  void setStudioType(String? type) {
    state = state.copyWith(filters: state.filters.copyWith(studioType: type));
    _performSearch();
  }

  /// Update backing vocal filter
  void setBackingVocalFilter(bool? canDoBacking) {
    state = state.copyWith(
      filters: state.filters.copyWith(canDoBackingVocal: canDoBacking),
    );
    _performSearch();
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(filters: state.filters.clearFilters());
    _performSearch();
  }

  /// Reset everything
  void reset() {
    state = state.copyWith(filters: const SearchFilters());
    _performSearch();
  }

  /// Refresh current search results
  Future<void> refresh() async {
    await _performSearch();
  }

  /// Debounced search for text input
  void _debouncedSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), _performSearch);
  }

  /// Execute search
  Future<void> _performSearch() async {
    final requestId = ++_currentRequestId;
    final user = ref.read(currentUserProfileProvider).value;
    final blockedUsers = user?.blockedUsers ?? [];

    state = state.copyWith(results: const AsyncValue.loading(), hasMore: true);

    try {
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
          // Start using Failure properly instead of generic error if possible, but for now:
          state = state.copyWith(
            results: AsyncValue.error(failure, StackTrace.current),
          );
        },
        (results) {
          if (_currentRequestId != requestId) return;

          final sortedResults = SearchRepository.sortByProximity(
            results,
            state.userLat,
            state.userLng,
          );

          state = state.copyWith(
            results: AsyncValue.data(sortedResults),
            hasMore: results.length >= SearchConfig.targetResults,
          );
        },
      );
    } catch (e, st) {
      if (_currentRequestId != requestId) return;
      debugPrint('[Search] Error: $e');
      state = state.copyWith(results: AsyncValue.error(e, st));
    }
  }
}

/// Provider for SearchController
final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);
