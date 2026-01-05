import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user_type.dart';
import '../data/search_repository.dart';
import 'widgets/user_card.dart';
import '../../../common_widgets/app_text_field.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';

/// Main search screen with text input and filterable results.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _debounce = Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Buscar', style: AppTypography.headlineMedium),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: AppTextField(
              controller: _searchController,
              label: 'Buscar',
              hint: 'Buscar músicos, bandas...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              onChanged: (value) {
                _debounce.run(() {
                  ref.read(searchFiltersProvider.notifier).updateQuery(value);
                });
              },
            ),
          ),

          // Type Filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: filters.type == null,
                  onSelected: (_) =>
                      ref.read(searchFiltersProvider.notifier).updateType(null),
                ),
                const SizedBox(width: 8),
                ...AppUserType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: type.label,
                      selected: filters.type == type,
                      onSelected: (_) => ref
                          .read(searchFiltersProvider.notifier)
                          .updateType(type),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s16),

          // Results
          Expanded(
            child: resultsAsync.when(
              data: (users) {
                if (!filters.hasActiveFilters) {
                  return const _EmptyState(
                    icon: Icons.search,
                    message: 'Digite algo para buscar',
                  );
                }

                if (users.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.search_off,
                    message: 'Nenhum resultado encontrado',
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) => UserCard(
                    user: users[index],
                    onTap: () {
                      // TODO: Navigate to profile view
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => _EmptyState(
                icon: Icons.error_outline,
                message: 'Erro: $error',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip for type selection.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: selected ? AppColors.background : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.background,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.surfaceHighlight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

/// Empty state placeholder.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.s16),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple debouncer for search input.
class Debouncer {
  final int milliseconds;
  VoidCallback? _action;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _action = action;
    Future.delayed(Duration(milliseconds: milliseconds), () {
      if (_action == action) {
        action();
      }
    });
  }
}
