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
    return _loadInitial(sectionType);
  }

  Future<FeedListState> _loadInitial(FeedSectionType sectionType) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      return const FeedListState(items: [], hasMore: false);
    }

    final feedRepo = ref.read(feedRepositoryProvider);
    final userLat = user.location?['lat'] as double?;
    final userLong = user.location?['lng'] as double?;
    final userGeohash = user.geohash;

    if (userLat != null && userLong != null) {
      return _loadWithLocation(
        feedRepo,
        user.uid,
        userLat,
        userLong,
        userGeohash,
        sectionType,
      );
    }

    return _loadClassic(feedRepo, user.uid, userLat, userLong, sectionType);
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

    switch (sectionType) {
      case FeedSectionType.nearby:
        filterType = null;
        break;
      case FeedSectionType.artists:
      case FeedSectionType.technicians:
        filterType = 'profissional';
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
      userGeohash: geohash,
    );

    return result.fold((failure) => throw failure, (allSorted) {
      final filteredItems = _applySectionFilter(allSorted, sectionType);
      final initialPage = filteredItems.take(_pageSize).toList();

      return FeedListState(
        items: initialPage,
        allSortedItems: filteredItems,
        currentPage: 1,
        hasMore: filteredItems.length > _pageSize,
      );
    });
  }

  Future<FeedListState> _loadClassic(
    FeedRepository feedRepo,
    String userId,
    double? lat,
    double? long,
    FeedSectionType sectionType,
  ) async {
    if (sectionType == FeedSectionType.nearby) {
      return const FeedListState(items: [], hasMore: false);
    }

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

    return FeedListState(items: items, hasMore: items.length >= _pageSize);
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
      if (currentState._allSortedItems.isNotEmpty) {
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
      } else if (currentState._lastDocument != null) {
        final user = ref.read(currentUserProfileProvider).value!;
        final feedRepo = ref.read(feedRepositoryProvider);

        String? type;
        if (sectionType == FeedSectionType.bands) type = 'banda';
        if (sectionType == FeedSectionType.studios) type = 'estudio';
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
            state = AsyncData(currentState.copyWith(isLoadingMore: false));
          },
          (response) {
            final filteredItems = _applySectionFilter(
              response.items,
              sectionType,
            );
            final existingIds = currentState.items.map((e) => e.uid).toSet();
            final uniqueItems = filteredItems
                .where((item) => !existingIds.contains(item.uid))
                .toList();

            state = AsyncData(
              currentState.copyWith(
                items: [...currentState.items, ...uniqueItems],
                lastDocument: response.lastDocument,
                hasMore: response.hasMore,
                isLoadingMore: false,
              ),
            );
          },
        );
      } else {
        state = AsyncData(
          currentState.copyWith(isLoadingMore: false, hasMore: false),
        );
      }
    } catch (e) {
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }

  List<FeedItem> _applySectionFilter(
    List<FeedItem> items,
    FeedSectionType sectionType,
  ) {
    if (sectionType == FeedSectionType.technicians) {
      return items.where(_isPureTechnician).toList();
    }

    if (sectionType == FeedSectionType.artists) {
      return items.where((item) => !_isPureTechnician(item)).toList();
    }

    return items;
  }

  bool _isPureTechnician(FeedItem item) {
    if (item.tipoPerfil != 'profissional') return false;

    final normalizedCategories = item.subCategories
        .map(_normalizeCategory)
        .where((value) => value.isNotEmpty)
        .toSet();

    final hasCrew = normalizedCategories.contains('crew');
    final hasMusicCategory =
        normalizedCategories.contains('singer') ||
        normalizedCategories.contains('instrumentalist') ||
        normalizedCategories.contains('dj');

    return hasCrew && !hasMusicCategory;
  }

  String _normalizeCategory(String value) {
    if (value.trim().isEmpty) return '';

    final normalized = value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    switch (normalized) {
      case 'crew':
      case 'equipe_tecnica':
      case 'equipe_tecnico':
      case 'tecnico':
      case 'tecnica':
        return 'crew';
      case 'cantor':
      case 'cantora':
      case 'cantor_a':
      case 'vocalista':
      case 'singer':
        return 'singer';
      case 'instrumentista':
      case 'instrumentalist':
        return 'instrumentalist';
      case 'dj':
        return 'dj';
      default:
        return normalized;
    }
  }
}
