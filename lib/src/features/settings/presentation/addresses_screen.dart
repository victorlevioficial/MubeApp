import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/location_service.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/components/patterns/fade_in_slide.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_effects.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../address/domain/resolved_address.dart';
import '../../address/presentation/address_flow.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../domain/saved_address.dart';
import '../domain/saved_address_book.dart';
import 'widgets/address_card.dart';
import 'widgets/settings_group.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  AppUser? _readCurrentUser() => ref.read(currentUserProfileProvider).value;

  List<SavedAddress> _resolveAddresses(AppUser? user) {
    if (user == null) return const [];
    return SavedAddressBook.effectiveAddresses(user);
  }

  List<SavedAddress> _readAddresses() => _resolveAddresses(_readCurrentUser());

  Future<void> _saveAddresses(
    List<SavedAddress> addresses, {
    required String successMessage,
  }) async {
    final user = _readCurrentUser();
    if (user == null) {
      throw StateError('Sessão expirada. Entre novamente.');
    }

    SavedAddressBook.validateLimit(addresses);
    final normalized = SavedAddressBook.sortAndNormalize(addresses);

    if (normalized.isNotEmpty) {
      final primary = normalized.first;
      if (primary.lat == null || primary.lng == null) {
        throw StateError('Endereço principal sem coordenadas válidas.');
      }
      if (primary.cidade.trim().isEmpty || primary.estado.trim().isEmpty) {
        throw StateError('Endereço principal sem cidade e estado válidos.');
      }
    }

    final updatedUser = SavedAddressBook.syncUser(user, normalized);
    final result = await ref
        .read(authRepositoryProvider)
        .updateUser(updatedUser);

    result.fold((failure) => throw StateError(failure.message), (_) => null);

    if (mounted) {
      AppSnackBar.success(context, successMessage);
    }
  }

  Future<void> _addAddress() async {
    final addresses = _readAddresses();
    if (addresses.length >= SavedAddressBook.maxAddresses) {
      AppSnackBar.warning(
        context,
        'Limite de ${SavedAddressBook.maxAddresses} endereços atingido.',
      );
      return;
    }
    if (!LocationService.isConfigured) {
      AppSnackBar.warning(
        context,
        'Serviço de busca indisponível. Configure a chave da Google API.',
      );
      return;
    }

    final selectedAddress = await showAddressSearchScreen(context);
    if (!mounted || selectedAddress == null) return;

    await _persistNewAddress(selectedAddress);
  }

  Future<void> _persistNewAddress(ResolvedAddress selectedAddress) async {
    if (!selectedAddress.canConfirm) {
      AppSnackBar.warning(
        context,
        selectedAddress.confirmBlockingReason ??
            'Escolha um endereço válido para salvar.',
      );
      return;
    }

    final updatedAddresses = SavedAddressBook.addAsPrimary(
      _readAddresses(),
      selectedAddress.toSavedAddress(isPrimary: true),
    );

    try {
      await _saveAddresses(
        updatedAddresses,
        successMessage: 'Endereço adicionado e definido como principal.',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Erro ao salvar endereço: $error');
    }
  }

  Future<void> _setAsPrimary(SavedAddress address) async {
    try {
      await _saveAddresses(
        SavedAddressBook.setPrimary(_readAddresses(), address),
        successMessage: 'Endereço principal atualizado.',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Erro ao atualizar endereço: $error');
    }
  }

  Future<void> _deleteAddress(SavedAddress address) async {
    if (_readAddresses().length <= 1) {
      AppSnackBar.warning(
        context,
        'Pelo menos 1 endereço deve permanecer salvo.',
      );
      return;
    }

    final confirmed = await AppOverlay.dialog<bool>(
      context: context,
      builder: (dialogContext) => const AppConfirmationDialog(
        title: 'Excluir endereço?',
        message: 'Deseja excluir este endereço salvo?',
        confirmText: 'Excluir',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    try {
      await _saveAddresses(
        SavedAddressBook.delete(_readAddresses(), address),
        successMessage: 'Endereço excluído.',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Erro ao excluir endereço: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Meus Endereços'),
      body: userAsync.when(
        loading: () => const Center(
          child: AppLoadingIndicator.withMessage('Carregando endereços...'),
        ),
        error: (_, _) => _buildBodySurface(
          child: EmptyStateWidget(
            icon: Icons.cloud_off_rounded,
            title: 'Não foi possível carregar seus endereços',
            subtitle: 'Tente novamente para recuperar seus locais salvos.',
            actionButton: AppButton.secondary(
              text: 'Tentar novamente',
              onPressed: () => ref.invalidate(currentUserProfileProvider),
              isFullWidth: true,
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return _buildBodySurface(
              child: const EmptyStateWidget(
                icon: Icons.lock_outline_rounded,
                title: 'Sessão expirada',
                subtitle: 'Entre novamente para gerenciar seus endereços.',
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
                      addresses: addresses,
                      canAddMore: canAddMore,
                      isSearchAvailable: LocationService.isConfigured,
                      onAddAddress: _addAddress,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  SettingsGroup(
                    title: 'Endereços salvos',
                    children: addresses.isEmpty
                        ? [_buildEmptyStateCard()]
                        : _buildAddressCards(addresses),
                  ),
                ],
              ),
            ),
          );
        },
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
        title: 'Nenhum endereço salvo',
        subtitle:
            'Adicione um endereço para definir sua localização principal no app.',
        actionButton: AppButton.secondary(
          text: 'Adicionar primeiro endereço',
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
    required this.addresses,
    required this.canAddMore,
    required this.isSearchAvailable,
    required this.onAddAddress,
  });

  final List<SavedAddress> addresses;
  final bool canAddMore;
  final bool isSearchAvailable;
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    final savedCount = addresses.length;
    final remaining = SavedAddressBook.maxAddresses - savedCount;
    final primaryAddress = addresses.isEmpty ? null : addresses.first;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceHighlight.withValues(alpha: 0.82),
            AppColors.surface.withValues(alpha: 0.96),
            AppColors.background,
          ],
        ),
        borderRadius: AppRadius.all24,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: AppEffects.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.all16,
                  boxShadow: AppEffects.buttonShadow,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVRO DE ENDEREÇOS',
                      style: AppTypography.settingsGroupTitle.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Gerencie seus endereços',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 22,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Defina um principal e mantenha até ${SavedAddressBook.maxAddresses} locais prontos para uso.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          _UsageBar(used: savedCount, max: SavedAddressBook.maxAddresses),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.bookmark_outline_rounded,
                  label: 'salvos',
                  value: '$savedCount',
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.add_location_alt_outlined,
                  label: 'restantes',
                  value: '$remaining',
                  accentColor: remaining == 0
                      ? AppColors.warning
                      : AppColors.info,
                ),
              ),
            ],
          ),
          if (primaryAddress != null) ...[
            const SizedBox(height: AppSpacing.s16),
            _PrimaryAddressPreview(address: primaryAddress),
          ],
          if (!isSearchAvailable) ...[
            const SizedBox(height: AppSpacing.s16),
            const _InfoBanner(
              icon: Icons.info_outline_rounded,
              message: 'Busca automática indisponível no momento.',
              color: AppColors.warning,
            ),
          ],
          const SizedBox(height: AppSpacing.s20),
          AppButton.primary(
            text: canAddMore
                ? 'Adicionar novo endereço'
                : 'Limite de ${SavedAddressBook.maxAddresses} endereços',
            onPressed: canAddMore ? onAddAddress : null,
            icon: const Icon(Icons.add_location_alt_outlined),
            size: AppButtonSize.large,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.used, required this.max});

  final int used;
  final int max;

  @override
  Widget build(BuildContext context) {
    final progress = max == 0 ? 0.0 : used / max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Capacidade',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.78),
              ),
            ),
            const Spacer(),
            Text(
              '$used/$max',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        ClipRRect(
          borderRadius: AppRadius.pill,
          child: Container(
            height: 8,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.pill,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.18),
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: AppRadius.all12,
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.75),
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

class _PrimaryAddressPreview extends StatelessWidget {
  const _PrimaryAddressPreview({required this.address});

  final SavedAddress address;

  @override
  Widget build(BuildContext context) {
    final subtitle = address.secondaryLine.trim().isNotEmpty
        ? address.secondaryLine.trim()
        : (address.cep.trim().isNotEmpty
              ? 'CEP ${address.cep.trim()}'
              : 'Pronto para uso como local principal.');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.22),
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: AppRadius.all12,
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Principal ativo',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  address.primaryLine,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.82),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.all16,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
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
