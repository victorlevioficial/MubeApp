import 'package:flutter/material.dart';
import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_spacing.dart';
import '../design_system/foundations/app_typography.dart';
import 'app_text_field.dart';
import 'primary_button.dart';

class AppSelectionModal extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> selectedItems;
  final bool allowMultiple;
  final String? searchHint;
  final String Function(String)? itemLabelBuilder;

  const AppSelectionModal({
    super.key,
    required this.title,
    required this.items,
    this.selectedItems = const [],
    this.allowMultiple = true,
    this.searchHint,
    this.itemLabelBuilder,
  });

  @override
  State<AppSelectionModal> createState() => _AppSelectionModalState();
}

class _AppSelectionModalState extends State<AppSelectionModal> {
  final _searchController = TextEditingController();
  late List<String> _filteredItems;
  late List<String> _tempSelectedItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _tempSelectedItems = List.from(widget.selectedItems);

    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final label = widget.itemLabelBuilder != null
            ? widget.itemLabelBuilder!(item)
            : item;
        return label.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleItem(String item) {
    setState(() {
      if (widget.allowMultiple) {
        if (_tempSelectedItems.contains(item)) {
          _tempSelectedItems.remove(item);
        } else {
          _tempSelectedItems.add(item);
        }
      } else {
        _tempSelectedItems = [item];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        color: AppColors.surface, // Lighter background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTypography.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
            child: AppTextField(
              controller: _searchController,
              label: 'Pesquisar',
              hint: widget.searchHint ?? 'Digite para buscar...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              itemCount: _filteredItems.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.surfaceHighlight),
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = _tempSelectedItems.contains(item);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    widget.itemLabelBuilder != null
                        ? widget.itemLabelBuilder!(item)
                        : item,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.semanticAction
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (v) => _toggleItem(item),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    // Colors handled by AppTheme
                  ),
                  onTap: () => _toggleItem(item),
                );
              },
            ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(AppSpacing.s24),
            decoration: const BoxDecoration(
              color: AppColors.surface, // Mach background
              border: Border(
                top: BorderSide(color: AppColors.surfaceHighlight),
              ),
            ),
            child: SafeArea(
              child: PrimaryButton(
                text: 'Confirmar seleção (${_tempSelectedItems.length})',
                onPressed: () => Navigator.pop(context, _tempSelectedItems),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
