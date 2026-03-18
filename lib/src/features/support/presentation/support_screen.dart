import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/chips/app_filter_chip.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_effects.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/text_utils.dart';
import '../data/faq_data.dart';

part 'support_screen_ui.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const String _supportEmail = 'suporte@mubeapp.com.br';
  static const String _allCategoriesLabel = 'Todas';

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = _allCategoriesLabel;

  String get _searchQuery => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  List<String> get _availableCategories => [
    _allCategoriesLabel,
    ...kFaqCategoryOrder,
  ];

  List<FAQItem> get _searchMatchedFaqs {
    final normalizedQuery = normalizeText(_searchQuery);
    if (normalizedQuery.isEmpty) return kAppFAQs;

    return kAppFAQs.where((faq) {
      final searchableText = normalizeText(
        '${faq.question} ${faq.answer} ${faq.category} ${faq.tags.join(' ')}',
      );
      return searchableText.contains(normalizedQuery);
    }).toList();
  }

  List<FAQItem> get _filteredFaqs {
    final searchResults = _searchMatchedFaqs;
    if (_selectedCategory == _allCategoriesLabel) return searchResults;
    return searchResults
        .where((faq) => faq.category == _selectedCategory)
        .toList();
  }

  Map<String, List<FAQItem>> _groupByCategory(List<FAQItem> items) {
    final grouped = <String, List<FAQItem>>{};
    for (final category in kFaqCategoryOrder) {
      final categoryItems = items
          .where((item) => item.category == category)
          .toList();
      if (categoryItems.isNotEmpty) {
        grouped[category] = categoryItems;
      }
    }
    return grouped;
  }

  int _categoryCount(String category) {
    if (category == _allCategoriesLabel) return _searchMatchedFaqs.length;
    return _searchMatchedFaqs.where((faq) => faq.category == category).length;
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = _allCategoriesLabel;
      _searchController.clear();
    });
  }

  Future<void> _openSupportEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: const {'subject': 'Suporte Mube'},
    );

    try {
      final opened = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (opened || !mounted) return;
    } catch (e, st) {
      // Fallback para copiar o e-mail abaixo.
      AppLogger.warning('Falha ao abrir app de e-mail, usando fallback', e, st);
    }

    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!mounted) return;
    AppSnackBar.info(
      context,
      'Não foi possível abrir o app de e-mail. Endereço copiado.',
    );
  }

  Future<void> _copySupportEmail() async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!mounted) return;
    AppSnackBar.success(context, 'E-mail de suporte copiado.');
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _filteredFaqs;
    final groupedFaqs = _groupByCategory(filteredFaqs);
    final hasActiveFilters =
        _selectedCategory != _allCategoriesLabel || _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Ajuda e Suporte'),
      body: SingleChildScrollView(
        padding: AppSpacing.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntroCard(),
            const SizedBox(height: AppSpacing.s24),
            _buildActionCards(context),
            const SizedBox(height: AppSpacing.s24),
            _buildFaqHeader(
              total: filteredFaqs.length,
              hasActiveFilters: hasActiveFilters,
            ),
            const SizedBox(height: AppSpacing.s12),
            _buildSearchField(),
            const SizedBox(height: AppSpacing.s12),
            _buildCategoryFilters(),
            const SizedBox(height: AppSpacing.s16),
            if (filteredFaqs.isEmpty)
              _buildEmptyState()
            else
              ...groupedFaqs.entries.expand((entry) {
                return [
                  _buildCategorySection(entry.key, entry.value),
                  const SizedBox(height: AppSpacing.s16),
                ];
              }),
            _buildContactCard(context),
            const SizedBox(height: AppSpacing.s24),
          ],
        ),
      ),
    );
  }
}
