import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/app_refresh_indicator.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import 'widgets/feed_card_full.dart';

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
  Set<String> _favorites = {};
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadFavorites();
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

  Future<void> _loadFavorites() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    final feedRepo = ref.read(feedRepositoryProvider);
    final favorites = await feedRepo.getUserFavorites(user.uid);

    if (mounted) {
      setState(() => _favorites = favorites);
    }
  }

  Future<void> _loadItems() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    final feedRepo = ref.read(feedRepositoryProvider);
    final userLat = user.location?['lat'] as double?;
    final userLong = user.location?['long'] as double?;

    try {
      List<FeedItem> newItems;

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
        case FeedSectionType.bands:
          newItems = await feedRepo.getUsersByType(
            type: 'banda',
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
        case FeedSectionType.studios:
          newItems = await feedRepo.getUsersByType(
            type: 'estudio',
            currentUserId: user.uid,
            userLat: userLat,
            userLong: userLong,
            limit: 20,
          );
          break;
      }

      if (mounted) {
        setState(() {
          _items.clear();
          _items.addAll(newItems);
          _isLoading = false;
          _hasMore = newItems.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    // TODO: Implement pagination with startAfter
  }

  Future<void> _toggleFavorite(FeedItem item) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    final feedRepo = ref.read(feedRepositoryProvider);
    final wasFavorited = _favorites.contains(item.uid);

    // Optimistic update
    setState(() {
      if (wasFavorited) {
        _favorites.remove(item.uid);
      } else {
        _favorites.add(item.uid);
      }
    });

    try {
      await feedRepo.toggleFavorite(userId: user.uid, targetId: item.uid);

      // Refresh to get updated count
      _loadItems();
    } catch (e) {
      // Revert on error
      setState(() {
        if (wasFavorited) {
          _favorites.add(item.uid);
        } else {
          _favorites.remove(item.uid);
        }
      });
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(_getTitle(), style: AppTypography.titleMedium),
        centerTitle: true,
      ),
      body: AppRefreshIndicator(
        onRefresh: _loadItems,
        child: _isLoading && _items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
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
                  return FeedCardFull(
                    item: item,
                    isFavorited: _favorites.contains(item.uid),
                    onTap: () {
                      // TODO: Navigate to public profile
                    },
                    onFavoriteTap: () => _toggleFavorite(item),
                  );
                },
              ),
      ),
    );
  }
}
