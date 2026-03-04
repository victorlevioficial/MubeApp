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
  final _locationService = LocationService();
  bool _isUsingCurrentLocation = false;

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
      throw StateError('Sessao expirada. Entre novamente.');
    }

    SavedAddressBook.validateLimit(addresses);
    final normalized = SavedAddressBook.sortAndNormalize(addresses);

    if (normalized.isNotEmpty) {
      final primary = normalized.first;
      if (primary.lat == null || primary.lng == null) {
        throw StateError('Endereco principal sem coordenadas validas.');
      }
      if (primary.cidade.trim().isEmpty || primary.estado.trim().isEmpty) {
        throw StateError('Endereco principal sem cidade e estado validos.');
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
        'Limite de ${SavedAddressBook.maxAddresses} enderecos atingido.',
      );
      return;
    }
    if (!LocationService.isConfigured) {
      AppSnackBar.warning(
        context,
        'Servico de busca indisponivel. Configure a chave da Google API.',
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
            'Escolha um endereco valido para salvar.',
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
        successMessage: 'Endereco adicionado e definido como principal.',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Erro ao salvar endereco: $error');
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isUsingCurrentLocation) return;

    final addresses = _readAddresses();
    if (addresses.length >= SavedAddressBook.maxAddresses) {
      AppSnackBar.warning(
        context,
        'Limite de ${SavedAddressBook.maxAddresses} enderecos atingido.',
      );
      return;
    }
    if (!LocationService.isConfigured) {
      AppSnackBar.warning(
        context,
        'Servico de localizacao indisponivel sem a chave da Google API.',
      );
      return;
    }

    setState(() => _isUsingCurrentLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      final resolved = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      if (resolved == null) {
        AppSnackBar.warning(
          context,
          'Nao foi possivel determinar o endereco da localizacao atual.',
        );
        return;
      }

      final confirmed = await showAddressConfirmScreen(
        context,
        resolved,
        confirmButtonText: 'Salvar endereco',
      );
      if (!mounted || confirmed == null) return;

      await _persistNewAddress(confirmed);
    } on LocationServiceException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, _messageForLocationError(error));
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Nao foi possivel obter sua localizacao atual: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isUsingCurrentLocation = false);
      }
    }
  }

  String _messageForLocationError(LocationServiceException error) {
    switch (error.code) {
      case LocationServiceErrorCode.permissionDenied:
        return 'Permissao de localizacao negada.';
      case LocationServiceErrorCode.permissionDeniedForever:
        return 'Permissao de localizacao negada permanentemente.';
      case LocationServiceErrorCode.serviceDisabled:
        return 'GPS desativado. Ative o servico de localizacao.';
      case LocationServiceErrorCode.apiKeyMissing:
        return error.message;
      case LocationServiceErrorCode.quotaExceeded:
        return 'Limite da Google API atingido. Tente novamente mais tarde.';
      case LocationServiceErrorCode.requestFailed:
        return error.message;
    }
  }

  Future<void> _setAsPrimary(SavedAddress address) async {
    try {
      await _saveAddresses(
        SavedAddressBook.setPrimary(_readAddresses(), address),
        successMessage: 'Endereco principal atualizado.',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Erro ao atualizar endereco: $error');
    }
  }

  Future<void> _deleteAddress(SavedAddress address) async {
    if (_readAddresses().length <= 1) {
      AppSnackBar.warning(
        context,
        'Pelo menos 1 endereco deve permanecer salvo.',
      );
      return;
    }

    final confirmed = await AppOverlay.dialog<bool>(
      context: context,
      builder: (dialogContext) => const AppConfirmationDialog(
        title: 'Excluir endereco?',
        message: 'Deseja excluir este endereco salvo?',
        confirmText: 'Excluir',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    try {
      await _saveAddresses(
        SavedAddressBook.delete(_readAddresses(), address),
        successMessage: 'Endereco excluido.',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Erro ao excluir endereco: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Meus Enderecos'),
      body: userAsync.when(
        loading: () => const Center(
          child: AppLoadingIndicator.withMessage('Carregando enderecos...'),
        ),
        error: (_, _) => _buildBodySurface(
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
        ),
        data: (user) {
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
                      primaryAddress: addresses.isEmpty
                          ? null
                          : addresses.first,
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
