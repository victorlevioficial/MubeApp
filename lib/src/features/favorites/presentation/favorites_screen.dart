import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/common_widgets/mube_app_bar.dart';
import 'package:mube/src/design_system/foundations/app_colors.dart';
import 'package:mube/src/design_system/foundations/app_typography.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/favorites/domain/favorite_controller.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_card_vertical.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_skeleton.dart';

import 'widgets/favorites_filter_bar.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _selectedFilter = 'Todos';
  bool _isLoading = true;
  List<FeedItem> _allItems = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load favorites immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Ensure fresh list from server (or rely on controller's state if we trust it)
      // Getting IDs from controller.
      // Controller loads intially. We might want to refresh checking controller.
      // But for better UX, we assume controller state is reasonably up to date or synced.
      // We can also trigger a sync if needed.
      await ref.read(favoriteControllerProvider.notifier).loadFavorites();

      final favoriteState = ref.read(favoriteControllerProvider);
      final favoriteIds = favoriteState.localFavorites
          .toList(); // Use local/optimistic IDs

      if (favoriteIds.isEmpty) {
        if (mounted) {
          setState(() {
            _allItems = [];
            _isLoading = false;
          });
        }
        return;
      }

      final userId = ref.read(authRepositoryProvider).currentUser?.uid;
      // For location, we ideally need user location.
      // Passing null for now if not easily available, or fetching from location provider if exists.
      // Assuming feed repo can handle null lat/long (it does, distance will be null).

      final result = await ref
          .read(feedRepositoryProvider)
          .getUsersByIds(ids: favoriteIds, currentUserId: userId ?? '');

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _error = failure.message;
              _isLoading = false;
            });
          }
        },
        (items) {
          if (mounted) {
            setState(() {
              _allItems = items;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
      appBar: const MubeAppBar(title: 'Meus Favoritos', showBackButton: true),
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
              color: AppColors.brandPrimary,
              backgroundColor: AppColors.surface,
              onRefresh: _loadFavorites,
              child: _isLoading
                  ? ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: 6, // Show 6 skeletons
                      separatorBuilder: (context, index) =>
                          const SizedBox.shrink(),
                      itemBuilder: (context, index) => const FeedItemSkeleton(),
                    )
                  : _error != null
                  ? ListView(
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
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _filteredItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox.shrink(),
                      itemBuilder: (context, index) {
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
