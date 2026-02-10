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

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const String _supportEmail = 'suporte@mube.app';
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
      'Nao foi possivel abrir o app de e-mail. Endereco copiado.',
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

  Widget _buildIntroCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.all16,
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.surface2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      padding: AppSpacing.all16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: AppSpacing.all8,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  'Central de Ajuda do Mube',
                  style: AppTypography.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Respostas sobre conta, onboarding, MatchPoint, privacidade e atendimento tecnico.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          const Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              _TagPill(label: 'Conta'),
              _TagPill(label: 'Bandas'),
              _TagPill(label: 'MatchPoint'),
              _TagPill(label: 'LGPD'),
              _TagPill(label: 'Tickets'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    final newTicketCard = _SupportActionCard(
      icon: Icons.add_circle_outline,
      title: 'Novo Ticket',
      subtitle: 'Abra um chamado com anexos',
      color: AppColors.primary,
      onTap: () =>
          context.push('${RoutePaths.support}/${RoutePaths.supportCreate}'),
    );

    final myTicketsCard = _SupportActionCard(
      icon: Icons.history,
      title: 'Meus Tickets',
      subtitle: 'Acompanhe status e historico',
      color: AppColors.info,
      onTap: () =>
          context.push('${RoutePaths.support}/${RoutePaths.supportTickets}'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              newTicketCard,
              const SizedBox(height: AppSpacing.s12),
              myTicketsCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: newTicketCard),
            const SizedBox(width: AppSpacing.s12),
            Expanded(child: myTicketsCard),
          ],
        );
      },
    );
  }

  Widget _buildFaqHeader({required int total, required bool hasActiveFilters}) {
    final subtitle = _searchQuery.isNotEmpty
        ? '$total resultado(s) para "$_searchQuery"'
        : '$total resposta(s) disponiveis';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Perguntas Frequentes',
                style: AppTypography.headlineSmall,
              ),
            ),
            if (hasActiveFilters)
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Limpar',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: AppTypography.buttonPrimary.fontWeight,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return AppTextField(
      controller: _searchController,
      hint: 'Buscar por tema (ex: senha, banda, LGPD, ticket)',
      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
      suffixIcon: _searchQuery.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textSecondary,
              onPressed: _searchController.clear,
            ),
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildCategoryFilters() {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: _availableCategories.map((category) {
        final count = _categoryCount(category);
        return AppFilterChip(
          label: '$category ($count)',
          isSelected: _selectedCategory == category,
          onSelected: (_) {
            setState(() => _selectedCategory = category);
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategorySection(String category, List<FAQItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          child: Text(
            '$category (${items.length})',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: AppTypography.buttonPrimary.fontWeight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: items.map((faq) {
              final isLast = faq == items.last;
              return Column(
                children: [
                  ExpansionTile(
                    key: PageStorageKey('faq-${faq.category}-${faq.question}'),
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s4,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      0,
                      AppSpacing.s16,
                      AppSpacing.s16,
                    ),
                    title: Text(
                      faq.question,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: AppTypography.titleSmall.fontWeight,
                      ),
                    ),
                    textColor: AppColors.textPrimary,
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.textSecondary,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          faq.answer,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: AppColors.surfaceHighlight),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: AppSpacing.all16,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Nenhuma resposta encontrada para esse filtro.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppButton.ghost(
            text: 'Limpar busca e filtros',
            onPressed: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      padding: AppSpacing.all16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ainda precisa de atendimento humano?',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Se sua duvida nao foi resolvida no FAQ, abra um ticket para acompanhamento dentro do app ou fale com nossa equipe por e-mail.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton.primary(
            text: 'Abrir novo ticket',
            isFullWidth: true,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            onPressed: () => context.push(
              '${RoutePaths.support}/${RoutePaths.supportCreate}',
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  text: 'Enviar e-mail',
                  isFullWidth: true,
                  icon: const Icon(Icons.mail_outline, size: 18),
                  onPressed: () => unawaited(_openSupportEmail()),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: AppButton.ghost(
                  text: 'Copiar e-mail',
                  isFullWidth: true,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () => unawaited(_copySupportEmail()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            _supportEmail,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;

  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.75),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SupportActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
        boxShadow: AppEffects.subtleShadow,
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.all16,
          child: Padding(
            padding: AppSpacing.all16,
            child: Row(
              children: [
                Container(
                  padding: AppSpacing.all8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: AppTypography.titleSmall.fontWeight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
