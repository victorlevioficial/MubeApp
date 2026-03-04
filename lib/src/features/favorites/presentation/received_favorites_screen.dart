import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../feed/data/feed_repository.dart';
import '../../feed/domain/feed_item.dart';
import '../data/favorite_repository.dart';

class ReceivedFavoritesScreen extends ConsumerStatefulWidget {
  const ReceivedFavoritesScreen({super.key});

  @override
  ConsumerState<ReceivedFavoritesScreen> createState() =>
      _ReceivedFavoritesScreenState();
}

class _ReceivedFavoritesScreenState
    extends ConsumerState<ReceivedFavoritesScreen> {
  bool _isLoading = true;
  String? _error;
  List<FeedItem> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReceivedFavorites();
    });
  }

  Future<void> _loadReceivedFavorites() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;
    if (currentUserId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Usuario nao autenticado.';
        _items = const [];
      });
      return;
    }

    try {
      final currentUser = ref.read(currentUserProfileProvider).value;
      final userLat = (currentUser?.location?['lat'] as num?)?.toDouble();
      final userLng = (currentUser?.location?['lng'] as num?)?.toDouble();

      final favoriterIds = await ref
          .read(favoriteRepositoryProvider)
          .loadReceivedFavorites(expectedCount: currentUser?.favoritesCount);

      if (favoriterIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _items = const [];
        });
        return;
      }

      final result = await ref
          .read(feedRepositoryProvider)
          .getUsersByIds(
            ids: favoriterIds,
            currentUserId: currentUserId,
            userLat: userLat,
            userLong: userLng,
          );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _error = failure.message;
            _items = const [];
          });
        },
        (items) {
          final itemsById = {for (final item in items) item.uid: item};
          final orderedItems = favoriterIds
              .map((id) => itemsById[id])
              .whereType<FeedItem>()
              .toList();

          setState(() {
            _isLoading = false;
            _items = orderedItems;
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
        _items = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(
        title: 'Quem favoritou você',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _loadReceivedFavorites,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    const physics = AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    );

    if (_isLoading) {
      return ListView(
        physics: physics,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: physics,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Erro ao carregar favoritos recebidos',
              subtitle: 'Puxe para atualizar ou tente novamente.',
              actionButton: TextButton(
                onPressed: _loadReceivedFavorites,
                child: const Text('Tentar novamente'),
              ),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: physics,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Ninguém favoritou você ainda',
              subtitle:
                  'Quando alguem favoritar seu perfil, a lista aparece aqui.',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: physics,
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _ReceivedFavoriteTile(item: item);
      },
    );
  }
}

class _ReceivedFavoriteTile extends StatelessWidget {
  final FeedItem item;

  const _ReceivedFavoriteTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final subtitle = _buildSubtitle(item);

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.all16,
      child: InkWell(
        onTap: () => context.push('${RoutePaths.publicProfile}/${item.uid}'),
        borderRadius: AppRadius.all16,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s8,
            ),
            leading: _FavoriteAvatar(photoUrl: item.foto),
            title: Text(
              item.displayName,
              style: AppTypography.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: subtitle.isEmpty
                ? null
                : Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(FeedItem item) {
    final parts = <String>[];

    final category = item.categoria?.trim();
    if (category != null && category.isNotEmpty) {
      parts.add(category);
    }

    if (item.distanceText.isNotEmpty) {
      parts.add(item.distanceText);
    }

    return parts.join(' - ');
  }
}

class _FavoriteAvatar extends StatelessWidget {
  final String? photoUrl;

  const _FavoriteAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final imageProvider = photoUrl != null && photoUrl!.isNotEmpty
        ? CachedNetworkImageProvider(photoUrl!)
        : null;

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.surfaceHighlight,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.person_outline, color: AppColors.textSecondary)
          : null,
    );
  }
}
