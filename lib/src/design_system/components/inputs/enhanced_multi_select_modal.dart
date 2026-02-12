import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';
import '../buttons/app_button.dart';

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
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
    _selected = List.from(widget.selectedItems);
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
        .where((item) =>
            widget.itemLabel(item).toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _toggleItem(T item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        if (widget.maxSelections != null &&
            _selected.length >= widget.maxSelections!) {
          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Máximo de ${widget.maxSelections} seleções atingido',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        _selected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s16,
              AppSpacing.s24,
              AppSpacing.s16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: AppRadius.all8,
                    ),
                  ),
                ),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.headlineMedium,
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              widget.subtitle!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_selected.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s12,
                          vertical: AppSpacing.s4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: AppRadius.all16,
                        ),
                        child: Text(
                          '${_selected.length} selecionado${_selected.length > 1 ? 's' : ''}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: TextField(
                controller: _searchController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'Buscar...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.all12,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.all12,
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.all12,
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),

          // Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s8,
              ),
              itemCount: _filteredItems.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.s8),
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = _selected.contains(item);
                final label = widget.itemLabel(item);

                return GestureDetector(
                  onTap: () => _toggleItem(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: AppRadius.all12,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.transparent,
                            borderRadius: AppRadius.all8,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppColors.textPrimary,
                                )
                              : null,
                        ),

                        const SizedBox(width: AppSpacing.s12),

                        // Label
                        Expanded(
                          child: Text(
                            label,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
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
                    text: 'Confirmar${_selected.isNotEmpty ? ' (${_selected.length})' : ''}',
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
    );
  }
}


