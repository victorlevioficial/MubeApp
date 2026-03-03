import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';
import '../buttons/app_button.dart';
import '../feedback/app_snackbar.dart';
import 'app_text_field.dart';

/// Enhanced multi-select modal for choosing items like instruments, genres, services.
///
/// Provides a professional, intuitive selection UI with search and categories.
///
/// Example:
/// ```dart
/// final selected = await EnhancedMultiSelectModal.show<String>(
///   context: context,
///   title: 'Selecione seus instrumentos',
///   items: instruments,
///   selectedItems: currentSelection,
///   searchHint: 'Buscar instrumento...',
/// );
/// ```
class EnhancedMultiSelectModal<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) itemLabel;
  final String? searchHint;
  final int? maxSelections;
  final bool showSearch;

  const EnhancedMultiSelectModal({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.selectedItems,
    required this.itemLabel,
    this.searchHint,
    this.maxSelections,
    this.showSearch = true,
  });

  static Future<List<T>?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required List<T> items,
    required List<T> selectedItems,
    String Function(T)? itemLabel,
    String? searchHint,
    int? maxSelections,
    bool showSearch = true,
  }) {
    return showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.top24),
      builder: (context) => EnhancedMultiSelectModal<T>(
        title: title,
        subtitle: subtitle,
        items: items,
        selectedItems: selectedItems,
        itemLabel: itemLabel ?? (item) => item.toString(),
        searchHint: searchHint,
        maxSelections: maxSelections,
        showSearch: showSearch,
      ),
    );
  }

  @override
  State<EnhancedMultiSelectModal<T>> createState() =>
      _EnhancedMultiSelectModalState<T>();
}

class _EnhancedMultiSelectModalState<T>
    extends State<EnhancedMultiSelectModal<T>> {
  late List<T> _selected;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.selectedItems);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items
        .where(
          (item) => widget.itemLabel(item).toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  void _toggleItem(T item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
        return;
      }

      if (widget.maxSelections != null &&
          _selected.length >= widget.maxSelections!) {
        AppSnackBar.warning(
          context,
          'Maximo de ${widget.maxSelections} selecoes atingido.',
        );
        return;
      }

      _selected.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.top24,
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: maxHeight,
          child: Column(
            children: [
              _ModalHeader(
                title: widget.title,
                subtitle: widget.subtitle,
                selectedCount: _selected.length,
              ),
              if (widget.showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s8,
                  ),
                  child: AppTextField(
                    controller: _searchController,
                    hint: widget.searchHint ?? 'Buscar...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: _searchController.clear,
                          )
                        : null,
                    textInputAction: TextInputAction.search,
                  ),
                ),
              Expanded(
                child: _filteredItems.isEmpty
                    ? _EmptySelectionState(searchQuery: _searchController.text)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s16,
                          AppSpacing.s8,
                          AppSpacing.s16,
                          AppSpacing.s16,
                        ),
                        itemCount: _filteredItems.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s10),
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _SelectionTile(
                            key: ValueKey('${widget.title}-$index'),
                            label: widget.itemLabel(item),
                            isSelected: _selected.contains(item),
                            onTap: () => _toggleItem(item),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s20,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        text: 'Cancelar',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      flex: 2,
                      child: AppButton.primary(
                        text:
                            'Confirmar${_selected.isNotEmpty ? ' (${_selected.length})' : ''}',
                        onPressed: _selected.isNotEmpty
                            ? () => Navigator.of(context).pop(_selected)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({
    required this.title,
    required this.subtitle,
    required this.selectedCount,
  });

  final String title;
  final String? subtitle;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s24,
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.s16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: AppRadius.all8,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headlineMedium),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        subtitle!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selectedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: AppRadius.all16,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$selectedCount selecionado${selectedCount > 1 ? 's' : ''}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all16,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface2,
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.7)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.textPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySelectionState extends StatelessWidget {
  const _EmptySelectionState({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final hasQuery = searchQuery.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off_outlined : Icons.list_alt_outlined,
              size: 36,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              hasQuery
                  ? 'Nenhum resultado encontrado'
                  : 'Nenhum item disponivel',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              hasQuery
                  ? 'Tente outro termo para encontrar a opcao desejada.'
                  : 'Nao ha opcoes disponiveis para esta selecao.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
