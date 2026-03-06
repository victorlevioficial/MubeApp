part of 'support_screen.dart';

extension _SupportScreenUi on _SupportScreenState {
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
            'Respostas sobre conta, onboarding, MatchPoint, privacidade e atendimento técnico.',
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
      onTap: () => context.push(RoutePaths.supportCreatePath()),
    );

    final myTicketsCard = _SupportActionCard(
      icon: Icons.history,
      title: 'Meus Tickets',
      subtitle: 'Acompanhe status e histórico',
      color: AppColors.info,
      onTap: () => context.push(RoutePaths.supportTicketsPath()),
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
        : '$total resposta(s) disponíveis';

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
          onSelected: (_) => _selectCategory(category),
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
            'Se sua dúvida não foi resolvida no FAQ, abra um ticket para acompanhamento dentro do app ou fale com nossa equipe por e-mail.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton.primary(
            text: 'Abrir novo ticket',
            isFullWidth: true,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            onPressed: () => context.push(RoutePaths.supportCreatePath()),
          ),
          const SizedBox(height: AppSpacing.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    AppButton.outline(
                      text: 'Enviar e-mail',
                      isFullWidth: true,
                      icon: const Icon(Icons.mail_outline, size: 18),
                      onPressed: () => unawaited(_openSupportEmail()),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    AppButton.ghost(
                      text: 'Copiar e-mail',
                      isFullWidth: true,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () => unawaited(_copySupportEmail()),
                    ),
                  ],
                );
              }
              return Row(
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
              );
            },
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            _SupportScreenState._supportEmail,
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
