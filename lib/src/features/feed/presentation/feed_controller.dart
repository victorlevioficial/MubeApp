import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/typedefs.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_items_provider.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';

part 'feed_controller.g.dart';

// --- State Class (Manual) ---

@immutable
class FeedState {
  final bool isInitialLoading;
  final bool isLoadingMain;
  final bool hasMoreMain;
  final Map<FeedSectionType, List<FeedItem>> sectionItems;
  final List<FeedItem> mainItems;
  final String currentFilter;
  final int currentPage;

  const FeedState({
    this.isInitialLoading = true,
    this.isLoadingMain = false,
    this.hasMoreMain = true,
    this.sectionItems = const {},
    this.mainItems = const [],
    this.currentFilter = 'Todos',
    this.currentPage = 0,
  });

  FeedState copyWith({
    bool? isInitialLoading,
    bool? isLoadingMain,
    bool? hasMoreMain,
    Map<FeedSectionType, List<FeedItem>>? sectionItems,
    List<FeedItem>? mainItems,
    String? currentFilter,
    int? currentPage,
  }) {
    return FeedState(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMain: isLoadingMain ?? this.isLoadingMain,
      hasMoreMain: hasMoreMain ?? this.hasMoreMain,
      sectionItems: sectionItems ?? this.sectionItems,
      mainItems: mainItems ?? this.mainItems,
      currentFilter: currentFilter ?? this.currentFilter,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FeedState &&
        other.isInitialLoading == isInitialLoading &&
        other.isLoadingMain == isLoadingMain &&
        other.hasMoreMain == hasMoreMain &&
        mapEquals(other.sectionItems, sectionItems) &&
        listEquals(other.mainItems, mainItems) &&
        other.currentFilter == currentFilter &&
        other.currentPage == currentPage;
  }

  @override
  int get hashCode {
    return isInitialLoading.hashCode ^
        isLoadingMain.hashCode ^
        hasMoreMain.hashCode ^
        sectionItems.hashCode ^
        mainItems.hashCode ^
        currentFilter.hashCode ^
        currentPage.hashCode;
  }
}

// --- Controller (Riverpod Generator) ---

@Riverpod(keepAlive: true)
class FeedController extends _$FeedController {
  static const int _pageSize = 10;
  List<FeedItem> _allSortedUsers = [];
  double? _userLat;
  double? _userLong;

  @override
  FutureOr<FeedState> build() {
    return const FeedState();
  }

  Future<void> loadAllData() async {
    state = const AsyncValue.data(FeedState(isInitialLoading: true));

    // Set user location from auth profile
    final user = ref.read(currentUserProfileProvider).value;
    if (user != null) {
      _userLat = user.location?['lat'];
      _userLong = user.location?['lng'];
    }

    try {
      // Parallel loading
      final results = await Future.wait([
        _fetchSections(),
        _fetchMainFeed(reset: true),
      ]);

      final sections = results[0] as Map<FeedSectionType, List<FeedItem>>;
      // Main feed logic handled inside _fetchMainFeed but we update state here carefully

      final currentState = state.value ?? const FeedState();

      state = AsyncValue.data(
        currentState.copyWith(isInitialLoading: false, sectionItems: sections),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Map<FeedSectionType, List<FeedItem>>> _fetchSections() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return {};

    final feedRepo = ref.read(feedRepositoryProvider);
    final items = <FeedSectionType, List<FeedItem>>{};

    // Helper to extract result or default to empty list
    Future<List<FeedItem>> fetchOrEmpty(
      FutureResult<List<FeedItem>> call,
    ) async {
      final result = await call;
      return result.getOrElse((l) => []);
    }

    if (_userLat != null && _userLong != null) {
      items[FeedSectionType.nearby] = await fetchOrEmpty(
        feedRepo.getNearbyUsers(
          lat: _userLat!,
          long: _userLong!,
          radiusKm: 50,
          currentUserId: user.uid,
          limit: 10,
        ),
      );
    }

    items[FeedSectionType.artists] = await fetchOrEmpty(
      feedRepo.getArtists(
        currentUserId: user.uid,
        userLat: _userLat,
        userLong: _userLong,
        limit: 10,
      ),
    );

    items[FeedSectionType.bands] = await fetchOrEmpty(
      feedRepo.getUsersByType(
        type: ProfileType.band,
        currentUserId: user.uid,
        userLat: _userLat,
        userLong: _userLong,
        limit: 10,
      ),
    );

    // Update shared provider
    final allItems = items.values.expand((list) => list).toList();
    ref.read(feedItemsProvider.notifier).loadItems(allItems);

    // Preload images
    _preloadImages(allItems);

    return items;
  }

  Future<void> _fetchMainFeed({bool reset = false}) async {
    final currentState = state.value ?? const FeedState();

    if (currentState.isLoadingMain) return;
    if (!reset && !currentState.hasMoreMain) return;

    // Optimistic state update for loading
    state = AsyncValue.data(
      currentState.copyWith(
        isLoadingMain: true,
        currentPage: reset ? 0 : currentState.currentPage,
        hasMoreMain: reset ? true : currentState.hasMoreMain,
        mainItems: reset ? [] : currentState.mainItems,
      ),
    );

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    if (reset) {
      String? filterType;
      if (currentState.currentFilter == 'Músicos') {
        filterType = ProfileType.professional;
      }
      if (currentState.currentFilter == 'Bandas') filterType = ProfileType.band;
      if (currentState.currentFilter == 'Estúdios') {
        filterType = ProfileType.studio;
      }

      if (_userLat != null && _userLong != null) {
        final result = await ref
            .read(feedRepositoryProvider)
            .getAllUsersSortedByDistance(
              currentUserId: user.uid,
              userLat: _userLat!,
              userLong: _userLong!,
              filterType: filterType,
            );

        result.fold(
          (failure) {
            state = AsyncValue.error(failure.message, StackTrace.current);
            _allSortedUsers = [];
          },
          (success) {
            _allSortedUsers = success;
          },
        );

        if (state.hasError) return; // Exit if error occurred
      } else {
        _allSortedUsers = [];
      }
    }

    // Pagination locally on sorted list
    final page = reset ? 0 : currentState.currentPage;
    final startIndex = page * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, _allSortedUsers.length);

    final newItems = _allSortedUsers.sublist(startIndex, endIndex);

    // Sync with global item provider
    ref.read(feedItemsProvider.notifier).loadItems(newItems);

    // Preload images for smoother experience
    _preloadImages(newItems);

    state = AsyncValue.data(
      state.value!.copyWith(
        isLoadingMain: false,
        currentPage: page + 1,
        hasMoreMain: endIndex < _allSortedUsers.length,
        mainItems: reset ? newItems : [...currentState.mainItems, ...newItems],
      ),
    );
  }

  Future<void> loadMoreMainFeed() async {
    await _fetchMainFeed(reset: false);
  }

  void onFilterChanged(String filter) {
    if (state.value?.currentFilter == filter) return;

    state = AsyncValue.data(state.value!.copyWith(currentFilter: filter));
    _fetchMainFeed(reset: true);
  }

  /// Preloads avatar images into cache so they are ready when displayed
  void _preloadImages(List<FeedItem> items) {
    for (final item in items) {
      final photoUrl = item.foto;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        // Fire and forget - download to cache, ignore any errors
        DefaultCacheManager().downloadFile(photoUrl).then((_) {}).catchError((
          e,
        ) {
          // Ignore errors silently - preloading failure shouldn't crash app
          debugPrint('Preload error for $photoUrl: $e');
        });
      }
    }
  }
}
