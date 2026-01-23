import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_items_provider.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import '../../../constants/firestore_constants.dart';

// --- State Class ---

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
}

// --- Controller ---

class FeedController extends AsyncNotifier<FeedState> {
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

      state = AsyncValue.data(
        state.value!.copyWith(isInitialLoading: false, sectionItems: sections),
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

    try {
      if (_userLat != null && _userLong != null) {
        items[FeedSectionType.nearby] = await feedRepo.getNearbyUsers(
          lat: _userLat!,
          long: _userLong!,
          radiusKm: 50,
          currentUserId: user.uid,
          limit: 10,
        );
      }

      items[FeedSectionType.artists] = await feedRepo.getArtists(
        currentUserId: user.uid,
        userLat: _userLat,
        userLong: _userLong,
        limit: 10,
      );

      items[FeedSectionType.bands] = await feedRepo.getUsersByType(
        type: ProfileType.band,
        currentUserId: user.uid,
        userLat: _userLat,
        userLong: _userLong,
        limit: 10,
      );

      // Update shared provider
      final allItems = items.values.expand((list) => list).toList();
      ref.read(feedItemsProvider.notifier).loadItems(allItems);

      return items;
    } catch (e) {
      AppLogger.error('Error loading sections', e);
      return {};
    }
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

    try {
      if (reset) {
        String? filterType;
        if (currentState.currentFilter == 'Músicos') {
          filterType = ProfileType.professional;
        }
        if (currentState.currentFilter == 'Bandas')
          filterType = ProfileType.band;
        if (currentState.currentFilter == 'Estúdios')
          filterType = ProfileType.studio;

        if (_userLat != null && _userLong != null) {
          _allSortedUsers = await ref
              .read(feedRepositoryProvider)
              .getAllUsersSortedByDistance(
                currentUserId: user.uid,
                userLat: _userLat!,
                userLong: _userLong!,
                filterType: filterType,
              );
        } else {
          _allSortedUsers = [];
        }
      }

      // Pagination locally on sorted list
      final page = reset ? 0 : currentState.currentPage;
      final startIndex = page * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(
        0,
        _allSortedUsers.length,
      );

      final newItems = _allSortedUsers.sublist(startIndex, endIndex);

      // Sync with global item provider
      ref.read(feedItemsProvider.notifier).loadItems(newItems);

      state = AsyncValue.data(
        state.value!.copyWith(
          isLoadingMain: false,
          currentPage: page + 1,
          hasMoreMain: endIndex < _allSortedUsers.length,
          mainItems: reset
              ? newItems
              : [...currentState.mainItems, ...newItems],
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMoreMainFeed() async {
    await _fetchMainFeed(reset: false);
  }

  void onFilterChanged(String filter) {
    if (state.value?.currentFilter == filter) return;

    state = AsyncValue.data(state.value!.copyWith(currentFilter: filter));
    _fetchMainFeed(reset: true);
  }
}

// --- Provider ---

final feedControllerProvider = AsyncNotifierProvider<FeedController, FeedState>(
  FeedController.new,
);
