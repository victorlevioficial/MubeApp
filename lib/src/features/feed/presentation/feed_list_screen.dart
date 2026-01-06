import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_refresh_indicator.dart';
import '../../../common_widgets/app_shimmer.dart';
import '../../../common_widgets/mube_app_bar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_items_provider.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import 'widgets/feed_card_vertical.dart';

/// Full-screen list view for a feed section with pagination.
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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
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
          // Nearby doesn't support cursor-based pagination
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
          // Artists também não suporta paginação no método atual
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
          // Use paginated version to get cursor
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
          // Use paginated version to get cursor
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
        // Register items in centralized provider for reactive updates
        ref.read(feedItemsProvider.notifier).loadItems(newItems);

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
          // Nearby doesn't support pagination currently
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
        child: _isLoading && _items.isEmpty
            ? _buildLoadingSkeleton()
            : _items.isEmpty
            ? Center(
                child: Text(
                  'Nenhum resultado encontrado',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.s16),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  final item = _items[index];

                  return FeedCardVertical(
                    item: item,
                    onTap: () => context.push('/user/${item.uid}'),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: 6, // Show 6 skeleton cards
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s16),
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Avatar skeleton
              AppShimmer.circle(size: 56),
              const SizedBox(width: AppSpacing.s16),
              // Text content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmer.text(width: 140, height: 16),
                    const SizedBox(height: 8),
                    AppShimmer.text(width: 100, height: 12),
                    const SizedBox(height: 4),
                    AppShimmer.text(width: 80, height: 12),
                  ],
                ),
              ),
              // Favorite icon skeleton
              AppShimmer.circle(size: 32),
            ],
          ),
        );
      },
    );
  }
}
