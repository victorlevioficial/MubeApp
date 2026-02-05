import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/design_system/components/navigation/app_app_bar.dart';
import 'package:mube/src/design_system/foundations/tokens/app_colors.dart';
import 'package:mube/src/design_system/foundations/tokens/app_typography.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/favorites/domain/favorite_controller.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_card_vertical.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_loading_more.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_skeleton.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';

import 'widgets/favorites_filter_bar.dart';

abstract final class FavoritesConstants {
  static const double paginationThreshold = 200.0;
  static const int pageSize = 20;
}

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _selectedFilter = 'Todos';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<FeedItem> _allItems = [];
  String? _error;
  bool _hasMore = true;
  DocumentSnapshot? _lastFavoriteDoc;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load favorites immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final currentScroll = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;

      if (currentScroll >=
          maxScroll - FavoritesConstants.paginationThreshold) {
        _loadMoreFavorites();
      }
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _allItems = [];
      _hasMore = true;
      _lastFavoriteDoc = null;
    });

    try {
      // 1. Ensure fresh list from server (or rely on controller's state if we trust it)
      // Getting IDs from controller.
      // Controller loads intially. We might want to refresh checking controller.
      // But for better UX, we assume controller state is reasonably up to date or synced.
      // We can also trigger a sync if needed.
      await ref.read(favoriteControllerProvider.notifier).loadFavorites();
      await _fetchFavoritesPage(reset: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreFavorites() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    await _fetchFavoritesPage(reset: false);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _fetchFavoritesPage({required bool reset}) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.uid;

    // Get user location for distance calculation
    final currentUserProfile = ref.read(currentUserProfileProvider).value;
    final userLat = currentUserProfile?.location?['lat'] as double?;
    final userLng = currentUserProfile?.location?['lng'] as double?;

    final favoritesPage = await ref
        .read(favoriteRepositoryProvider)
        .loadFavoritesPage(
          startAfter: reset ? null : _lastFavoriteDoc,
          limit: FavoritesConstants.pageSize,
        );

    if (favoritesPage.favoriteIds.isEmpty) {
      if (mounted) {
        setState(() {
          _hasMore = false;
        });
      }
      return;
    }

    final result = await ref.read(feedRepositoryProvider).getUsersByIds(
          ids: favoritesPage.favoriteIds,
          currentUserId: userId ?? '',
          userLat: userLat,
          userLong: userLng,
        );

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            if (reset) {
              _error = failure.message;
            }
            _hasMore = false;
          });
        }
      },
      (items) {
        if (mounted) {
          final itemsById = {for (final item in items) item.uid: item};
          final orderedItems = favoritesPage.favoriteIds
              .map((id) => itemsById[id])
              .whereType<FeedItem>()
              .toList();

          final existingIds = _allItems.map((item) => item.uid).toSet();
          final newItems = orderedItems
              .where((item) => !existingIds.contains(item.uid))
              .toList();

          if (newItems.isNotEmpty) {
            ref
                .read(feedImagePrecacheServiceProvider)
                .precacheItems(context, newItems);
          }

          setState(() {
            _allItems = reset ? newItems : [..._allItems, ...newItems];
            _lastFavoriteDoc = favoritesPage.lastDocument;
            _hasMore = favoritesPage.hasMore;
          });
        }
      },
    );
  }

  List<FeedItem> get _filteredItems {
    if (_selectedFilter == 'Todos') {
      return _allItems;
    }

    return _allItems.where((item) {
      if (_selectedFilter == 'Músicos') {
        // Usually ProfileType.professional which is 'profissional' in our DB
        return item.tipoPerfil == 'profissional';
      } else if (_selectedFilter == 'Bandas') {
        return item.tipoPerfil == 'banda';
      } else if (_selectedFilter == 'Estúdios') {
        return item.tipoPerfil == 'estudio';
      } else if (_selectedFilter == 'Perto de mim') {
        // Distance check (e.g. within 50km)
        return (item.distanceKm ?? 999) < 50;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Meus Favoritos', showBackButton: true),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: FavoritesFilterBar(
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: _loadFavorites,
              child: _isLoading
                  ? ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: 6, // Show 6 skeletons
                      separatorBuilder: (context, index) =>
                          const SizedBox.shrink(),
                      itemBuilder: (context, index) => const FeedItemSkeleton(),
                    )
                  : _error != null
                  ? ListView(
                      controller: _scrollController,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Erro ao carregar favoritos',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadFavorites,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _filteredItems.isEmpty
                  ? ListView(
                      controller: _scrollController,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _allItems.isEmpty
                                    ? 'Você ainda não tem favoritos.'
                                    : 'Nenhum resultado para este filtro.',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredItems.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _filteredItems.length) {
                          if (_isLoadingMore) {
                            return const FeedLoadingMore();
                          }
                          return const SizedBox(height: 80);
                        }

                        final item = _filteredItems[index];
                        return FeedCardVertical(
                          item: item,
                          onTap: () => context.push('/user/${item.uid}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
