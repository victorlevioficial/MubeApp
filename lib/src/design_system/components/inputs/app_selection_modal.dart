import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';
import '../buttons/app_button.dart';
import '../chips/app_chip.dart';
import 'app_text_field.dart';

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
        color: AppColors.surface,
        borderRadius: AppRadius.top24,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: _filteredItems.map((item) {
                  final isSelected = _tempSelectedItems.contains(item);
                  final label = widget.itemLabelBuilder != null
                      ? widget.itemLabelBuilder!(item)
                      : item;

                  return AppChip.filter(
                    label: label,
                    isSelected: isSelected,
                    onTap: () => _toggleItem(item),
                  );
                }).toList(),
              ),
            ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(AppSpacing.s24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.surfaceHighlight),
              ),
            ),
            child: SafeArea(
              child: AppButton.primary(
                text: 'Confirmar seleção (${_tempSelectedItems.length})',
                onPressed: () => Navigator.pop(context, _tempSelectedItems),
                isFullWidth: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
