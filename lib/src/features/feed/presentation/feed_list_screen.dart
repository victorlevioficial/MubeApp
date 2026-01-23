import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/app_refresh_indicator.dart';
import '../../../common_widgets/mube_app_bar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import 'widgets/vertical_feed_list.dart';

/// Full-screen list view for a feed section with pagination.
/// Uses the reusable VerticalFeedList widget.
class FeedListScreen extends ConsumerStatefulWidget {
  final FeedSectionType sectionType;

  const FeedListScreen({super.key, required this.sectionType});

  @override
  ConsumerState<FeedListScreen> createState() => _FeedListScreenState();
}

class _FeedListScreenState extends ConsumerState<FeedListScreen> {
  final _scrollController = ScrollController();
  final _items = <FeedItem>[];
  List<FeedItem> _allSortedItems = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    try {
      final feedRepo = ref.read(feedRepositoryProvider);
      final userLat = user.location?['lat'] as double?;
      final userLong = user.location?['lng'] as double?;
      final userGeohash = user.geohash;

      if (userLat != null && userLong != null) {
        // Use proximity sorting for everything if location is available
        String? filterType;
        String? category;
        String? excludeCategory;

        switch (widget.sectionType) {
          case FeedSectionType.nearby:
            filterType = null; // Shows everything
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

        _allSortedItems = await feedRepo.getAllUsersSortedByDistance(
          currentUserId: user.uid,
          userLat: userLat,
          userLong: userLong,
          filterType: filterType,
          category: category,
          excludeCategory: excludeCategory,
          userGeohash: userGeohash,
        );

        if (mounted) {
          setState(() {
            _items.clear();
            _items.addAll(_allSortedItems.take(_pageSize));
            _currentPage = 1;
            _hasMore = _allSortedItems.length > _pageSize;
            _isLoading = false;
            // No lastDocument needed for local pagination
          });
        }
      } else {
        // Fallback to classic pagination if no distance logic can be applied
        await _loadItemsClassicFallback(feedRepo, user.uid, userLat, userLong);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadItemsClassicFallback(
    FeedRepository feedRepo,
    String userId,
    double? userLat,
    double? userLong,
  ) async {
    List<FeedItem> newItems = [];
    DocumentSnapshot? lastDoc;

    switch (widget.sectionType) {
      case FeedSectionType.nearby:
        newItems = []; // Cannot show nearby without location
        break;
      case FeedSectionType.artists:
        newItems = await feedRepo.getArtists(
          currentUserId: userId,
          userLat: userLat,
          userLong: userLong,
          limit: _pageSize,
        );
        break;
      case FeedSectionType.technicians:
        newItems = await feedRepo.getTechnicians(
          currentUserId: userId,
          userLat: userLat,
          userLong: userLong,
          limit: _pageSize,
        );
        break;
      case FeedSectionType.bands:
        final response = await feedRepo.getUsersByTypePaginated(
          type: 'banda',
          currentUserId: userId,
          userLat: userLat,
          userLong: userLong,
          limit: _pageSize,
        );
        newItems = response.items;
        lastDoc = response.lastDocument;
        break;
      case FeedSectionType.studios:
        final response = await feedRepo.getUsersByTypePaginated(
          type: 'estudio',
          currentUserId: userId,
          userLat: userLat,
          userLong: userLong,
          limit: _pageSize,
        );
        newItems = response.items;
        lastDoc = response.lastDocument;
        break;
    }

    if (mounted) {
      setState(() {
        _items.clear();
        _items.addAll(newItems);
        _isLoading = false;
        _hasMore = newItems.length >= _pageSize;
        _lastDocument = lastDoc;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    if (_allSortedItems.isNotEmpty) {
      // Local pagination for distance-sorted items
      setState(() => _isLoadingMore = true);
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(
        0,
        _allSortedItems.length,
      );
      final nextItems = _allSortedItems.sublist(startIndex, endIndex);

      if (mounted) {
        setState(() {
          _items.addAll(nextItems);
          _currentPage++;
          _hasMore = endIndex < _allSortedItems.length;
          _isLoadingMore = false;
        });
      }
      return;
    }

    // Classic remote pagination fallback
    if (_lastDocument == null) return;
    setState(() => _isLoadingMore = true);

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    final feedRepo = ref.read(feedRepositoryProvider);
    final userLat = user.location?['lat'] as double?;
    final userLong = user.location?['lng'] as double?;

    try {
      String? type;
      switch (widget.sectionType) {
        case FeedSectionType.bands:
          type = 'banda';
          break;
        case FeedSectionType.studios:
          type = 'estudio';
          break;
        case FeedSectionType.artists:
        case FeedSectionType.technicians:
          type = 'profissional';
          break;
        case FeedSectionType.nearby:
          setState(() => _hasMore = false);
          return;
      }

      final response = await feedRepo.getUsersByTypePaginated(
        type: type,
        currentUserId: user.uid,
        userLat: userLat,
        userLong: userLong,
        limit: _pageSize,
        startAfter: _lastDocument,
      );

      if (mounted) {
        setState(() {
          _items.addAll(response.items);
          _lastDocument = response.lastDocument;
          _hasMore = response.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  String _getTitle() {
    final section = FeedSection.homeSections.firstWhere(
      (s) => s.type == widget.sectionType,
      orElse: () =>
          const FeedSection(type: FeedSectionType.artists, title: 'Resultados'),
    );
    return section.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MubeAppBar(title: _getTitle()),
      body: AppRefreshIndicator(
        onRefresh: _loadItems,
        child: VerticalFeedList(
          items: _items,
          isLoading: _isLoading,
          hasMore: _hasMore,
          isLoadingMore: _isLoadingMore,
          onLoadMore: _loadMore,
          scrollController: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        ),
      ),
    );
  }
}
