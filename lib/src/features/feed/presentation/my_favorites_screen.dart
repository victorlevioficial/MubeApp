import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../common_widgets/mube_app_bar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../data/favorites_provider.dart';
import '../domain/feed_item.dart';
import 'widgets/feed_card_vertical.dart';
import 'widgets/feed_skeleton.dart';
import 'widgets/quick_filter_bar.dart';

/// Tela "Meus Favoritos" - Versão Profissional
///
/// O [likedProfilesProvider] usa autoDispose, então:
/// - Cache é limpo automaticamente quando a tela fecha
/// - Shimmer aparece sempre que a tela abre
/// - Dados frescos são carregados do Firestore
class MyFavoritesScreen extends ConsumerStatefulWidget {
  const MyFavoritesScreen({super.key});

  @override
  ConsumerState<MyFavoritesScreen> createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends ConsumerState<MyFavoritesScreen> {
  String _currentFilter = 'Todos';

  void _onFilterChanged(String filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  bool _applyFilter(FeedItem item) {
    if (_currentFilter == 'Todos') return true;
    if (_currentFilter == 'Perto de mim') return true;

    final role = item.tipoPerfil.toLowerCase();

    if (_currentFilter == 'Músicos') {
      return role != 'banda' && role != 'estudio' && role != 'estúdio';
    }
    if (_currentFilter == 'Bandas') {
      return role == 'banda';
    }
    if (_currentFilter == 'Estúdios') {
      return role == 'estudio' || role == 'estúdio';
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Login necessário')));
    }

    // Provider com autoDispose - sempre mostra shimmer ao abrir
    final favoritesAsync = ref.watch(likedProfilesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MubeAppBar(title: 'Meus Favoritos'),
      body: Column(
        children: [
          // Quick Filters
          QuickFilterBar(
            selectedFilter: _currentFilter,
            onFilterSelected: _onFilterChanged,
          ),

          // Lista de Favoritos
          Expanded(
            child: favoritesAsync.when(
              loading: () => _buildShimmerList(),
              error: (error, stack) => _buildEmptyState(
                icon: Icons.error_outline,
                title: 'Erro ao carregar',
                subtitle: 'Tente novamente mais tarde.',
                buttonText: 'Recarregar',
                onAction: () => ref.invalidate(likedProfilesProvider),
              ),
              data: (items) => _buildListContent(items),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(List<FeedItem> allItems) {
    // Aplica filtro de categoria
    final visibleItems = allItems.where(_applyFilter).toList();

    // Estado: Lista vazia
    if (visibleItems.isEmpty) {
      if (_currentFilter != 'Todos' && _currentFilter != 'Perto de mim') {
        return _buildEmptyState(
          icon: Icons.filter_list_off,
          title: 'Nenhum resultado encontrado',
          subtitle: 'Tente mudar o filtro para ver seus favoritos.',
          buttonText: 'Limpar Filtros',
          onAction: () => _onFilterChanged('Todos'),
        );
      }
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Você ainda não tem favoritos',
        subtitle: 'Explore o feed para encontrar músicos e bandas incríveis.',
        buttonText: 'Explorar Feed',
        onAction: () => context.pop(),
      );
    }

    // Estado: Lista com itens
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: visibleItems.length,
      itemBuilder: (context, index) {
        final item = visibleItems[index];
        return FeedCardVertical(
          item: item,
          onTap: () => context.push('/user/${item.uid}'),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceHighlight,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: 6,
        itemBuilder: (context, index) => const FeedCardSkeleton(),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
