part of 'addresses_screen.dart';

extension _AddressesScreenUi on _AddressesScreenState {
  Widget _buildLoadingState() {
    return const Center(
      child: AppLoadingIndicator.withMessage('Carregando enderecos...'),
    );
  }

  Widget _buildLoadErrorState() {
    return _buildBodySurface(
      child: EmptyStateWidget(
        icon: Icons.cloud_off_rounded,
        title: 'Nao foi possivel carregar seus enderecos',
        subtitle: 'Tente novamente para recuperar seus locais salvos.',
        actionButton: AppButton.secondary(
          text: 'Tentar novamente',
          onPressed: () => ref.invalidate(currentUserProfileProvider),
          isFullWidth: true,
        ),
      ),
    );
  }

  Widget _buildUserContent(AppUser? user) {
    if (user == null) {
      return _buildBodySurface(
        child: const EmptyStateWidget(
          icon: Icons.lock_outline_rounded,
          title: 'Sessao expirada',
          subtitle: 'Entre novamente para gerenciar seus enderecos.',
        ),
      );
    }

    final addresses = _resolveAddresses(user);
    final canAddMore = addresses.length < SavedAddressBook.maxAddresses;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s16,
          AppSpacing.s32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInSlide(
              direction: FadeInSlideDirection.btt,
              child: _AddressesOverviewCard(
                savedCount: addresses.length,
                primaryAddress: addresses.isEmpty ? null : addresses.first,
                canAddMore: canAddMore,
                isSearchAvailable: LocationService.isConfigured,
                isUsingCurrentLocation: _isUsingCurrentLocation,
                onAddAddress: _addAddress,
                onUseCurrentLocation: _useCurrentLocation,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            SettingsGroup(
              title: 'Enderecos salvos',
              children: addresses.isEmpty
                  ? [_buildEmptyStateCard()]
                  : _buildAddressCards(addresses),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAddressCards(List<SavedAddress> addresses) {
    return [
      for (var index = 0; index < addresses.length; index++)
        Padding(
          padding: EdgeInsets.only(
            bottom: index == addresses.length - 1 ? 0 : AppSpacing.s12,
          ),
          child: FadeInSlide(
            key: ValueKey('address-card-${addresses[index].id}'),
            delay: Duration(milliseconds: 120 + (index * 70)),
            direction: FadeInSlideDirection.btt,
            child: AddressCard(
              address: addresses[index],
              onSetPrimary: () => _setAsPrimary(addresses[index]),
              onDelete: () => _deleteAddress(addresses[index]),
              canDelete: addresses.length > 1,
            ),
          ),
        ),
    ];
  }

  Widget _buildEmptyStateCard() {
    return _StateSurface(
      child: EmptyStateWidget(
        icon: Icons.location_off_outlined,
        title: 'Nenhum endereco salvo',
        subtitle:
            'Adicione um endereco para definir sua localizacao principal no app.',
        actionButton: AppButton.secondary(
          text: 'Adicionar primeiro endereco',
          onPressed: _addAddress,
          icon: const Icon(Icons.add_location_alt_outlined),
          isFullWidth: true,
        ),
      ),
    );
  }

  Widget _buildBodySurface({required Widget child}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: _StateSurface(child: child),
      ),
    );
  }
}

class _AddressesOverviewCard extends StatelessWidget {
  const _AddressesOverviewCard({
    required this.savedCount,
    required this.primaryAddress,
    required this.canAddMore,
    required this.isSearchAvailable,
    required this.isUsingCurrentLocation,
    required this.onAddAddress,
    required this.onUseCurrentLocation,
  });

  final int savedCount;
  final SavedAddress? primaryAddress;
  final bool canAddMore;
  final bool isSearchAvailable;
  final bool isUsingCurrentLocation;
  final VoidCallback onAddAddress;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final canUseCurrentLocation = canAddMore && isSearchAvailable;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all20,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: AppRadius.all12,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gerenciar enderecos',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      '$savedCount de ${SavedAddressBook.maxAddresses} enderecos salvos',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (primaryAddress != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.18),
                borderRadius: AppRadius.all12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Endereco principal',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    primaryAddress!.primaryLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (primaryAddress!.secondaryLine.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      primaryAddress!.secondaryLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (!isSearchAvailable) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Busca automatica indisponivel no momento.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          AppButton.primary(
            text: canAddMore
                ? 'Adicionar novo endereco'
                : 'Limite de ${SavedAddressBook.maxAddresses} enderecos',
            onPressed: canAddMore ? onAddAddress : null,
            icon: const Icon(Icons.add_location_alt_outlined),
            size: AppButtonSize.medium,
            isFullWidth: true,
          ),
          const SizedBox(height: AppSpacing.s10),
          AppButton.outline(
            text: 'Usar minha localizacao atual',
            onPressed: canUseCurrentLocation ? onUseCurrentLocation : null,
            isLoading: isUsingCurrentLocation,
            icon: const Icon(Icons.my_location_outlined, size: 18),
            size: AppButtonSize.medium,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _StateSurface extends StatelessWidget {
  const _StateSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: AppRadius.all24,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
        ),
        boxShadow: AppEffects.subtleShadow,
      ),
      child: child,
    );
  }
}
