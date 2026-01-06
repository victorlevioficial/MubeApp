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
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
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

    final feedRepo = ref.read(feedRepositoryProvider);
    final userLat = user.location?['lat'] as double?;
    final userLong = user.location?['lng'] as double?;

    try {
      List<FeedItem> newItems;
      DocumentSnapshot? lastDoc;

      switch (widget.sectionType) {
        case FeedSectionType.nearby:
          if (userLat != null && userLong != null) {
            newItems = await feedRepo.getNearbyUsers(
              lat: userLat,
              long: userLong,
              radiusKm: 20,
              currentUserId: user.uid,
              limit: 20,
            );
          } else {
            newItems = [];
          }
          break;

        case FeedSectionType.artists:
          newItems = await feedRepo.getArtists(
            currentUserId: user.uid,
            userLat: userLat,
            userLong: userLong,
            limit: 20,
          );
          break;

        case FeedSectionType.technicians:
          newItems = await feedRepo.getTechnicians(
            currentUserId: user.uid,
            userLat: userLat,
            userLong: userLong,
            limit: 20,
          );
          break;

        case FeedSectionType.bands:
          final response = await feedRepo.getUsersByTypePaginated(
            type: 'banda',
            currentUserId: user.uid,
            userLat: userLat,
            userLong: userLong,
            limit: 20,
          );
          newItems = response.items;
          lastDoc = response.lastDocument;
          break;

        case FeedSectionType.studios:
          final response = await feedRepo.getUsersByTypePaginated(
            type: 'estudio',
            currentUserId: user.uid,
            userLat: userLat,
            userLong: userLong,
            limit: 20,
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
          _hasMore = newItems.length >= 20;
          _lastDocument = lastDoc;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

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
        limit: 20,
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
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
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
