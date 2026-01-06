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
import '../data/favorites_provider.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import 'widgets/feed_card_vertical.dart';

/// Screen displaying user's favorited profiles
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<FeedItem> _items = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      setState(() {
        _error = 'Usuário não autenticado';
        _isLoading = false;
      });
      return;
    }

    try {
      final feedRepo = ref.read(feedRepositoryProvider);
      final userLat = user.location?['lat'] as double?;
      final userLong = user.location?['lng'] as double?;

      final items = await feedRepo.getFavoriteItems(
        userId: user.uid,
        userLat: userLat,
        userLong: userLong,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar favoritos: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(FeedItem item) async {
    final notifier = ref.read(favoritesProvider.notifier);
    await notifier.toggleFavorite(item.uid);

    // Reload favorites to reflect changes
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesCount = ref.watch(favoritesCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MubeAppBar(
        title: favoritesCount > 0
            ? 'Meus Favoritos ($favoritesCount)'
            : 'Meus Favoritos',
      ),
      body: AppRefreshIndicator(onRefresh: _loadFavorites, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              _error!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s24),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Nenhum favorito ainda',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s48),
              child: Text(
                'Explore o feed e favorite perfis que você gosta!',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.s32),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.explore),
              label: const Text('Explorar Feed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s24,
                  vertical: AppSpacing.s12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isFavorited = ref.watch(isFavoritedProvider(item.uid));

        return FeedCardVertical(
          item: item,
          isFavorited: isFavorited,
          onTap: () => context.push('/user/${item.uid}'),
          onFavorite: () => _toggleFavorite(item),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: 6,
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
              AppShimmer.circle(size: 56),
              const SizedBox(width: AppSpacing.s16),
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
              AppShimmer.circle(size: 32),
            ],
          ),
        );
      },
    );
  }
}
