import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../common_widgets/location_service.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../../design_system/components/patterns/full_width_selection_card.dart';
import '../../../../design_system/components/patterns/onboarding_section_card.dart';
import '../../../../design_system/components/patterns/or_divider.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../address/domain/resolved_address.dart';
import '../../../address/presentation/address_flow.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';

class OnboardingAddressStep extends ConsumerStatefulWidget {
  const OnboardingAddressStep({
    super.key,
    required this.onNext,
    required this.onBack,
    this.initialLocationLabel,
  });

  final Future<void> Function() onNext;
  final VoidCallback onBack;
  final String? initialLocationLabel;

  @override
  ConsumerState<OnboardingAddressStep> createState() =>
      _OnboardingAddressStepState();
}

class _OnboardingAddressStepState extends ConsumerState<OnboardingAddressStep> {
  final _locationService = LocationService();
  bool _isLoadingLocation = false;

  Future<void> _openSearch() async {
    if (!LocationService.isConfigured) {
      AppSnackBar.warning(
        context,
        'Servico de busca indisponivel. Configure a chave da Google API.',
      );
      return;
    }

    await showAddressSearchScreen(
      context,
      confirmButtonText: 'Finalizar',
      onConfirmAddress: _submitConfirmedAddress,
    );
  }

  Future<void> _reviewAndFinish(ResolvedAddress address) async {
    await showAddressConfirmScreen(
      context,
      address,
      confirmButtonText: 'Finalizar',
      onConfirmed: _submitConfirmedAddress,
    );
  }

  Future<bool> _submitConfirmedAddress(ResolvedAddress address) async {
    ref.read(onboardingFormProvider.notifier).updateResolvedAddress(address);
    await widget.onNext();
    // A successful submit can immediately replace this route.
    if (!mounted) return true;

    final submitState = ref.read(onboardingControllerProvider);
    if (submitState.hasError) {
      AppSnackBar.error(
        context,
        'Nao foi possivel concluir o cadastro. Tente novamente.',
      );
      return false;
    }

    return true;
  }

  Future<void> _useCurrentLocation() async {
    if (_isLoadingLocation) return;
    if (!LocationService.isConfigured) {
      AppSnackBar.warning(
        context,
        'Servico de localizacao indisponivel sem a chave da Google API.',
      );
      return;
    }

    setState(() => _isLoadingLocation = true);
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

      await showAddressConfirmScreen(
        context,
        resolved,
        confirmButtonText: 'Finalizar',
        onConfirmed: _submitConfirmedAddress,
      );
    } on LocationServiceException catch (error) {
      if (!mounted) return;
      await _showLocationError(error);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Nao foi possivel obter sua localizacao atual.',
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _showLocationError(LocationServiceException error) async {
    switch (error.code) {
      case LocationServiceErrorCode.permissionDeniedForever:
        AppSnackBar.warning(
          context,
          'Permissao de localizacao negada permanentemente. Abra as configuracoes do dispositivo.',
        );
        await Geolocator.openAppSettings();
        return;
      case LocationServiceErrorCode.permissionDenied:
        AppSnackBar.warning(
          context,
          'Permissao de localizacao negada. Ative nas configuracoes do dispositivo.',
        );
        return;
      case LocationServiceErrorCode.serviceDisabled:
        AppSnackBar.warning(
          context,
          'GPS desativado. Ative o servico de localizacao.',
        );
        return;
      case LocationServiceErrorCode.apiKeyMissing:
        AppSnackBar.warning(context, error.message);
        return;
      case LocationServiceErrorCode.quotaExceeded:
        AppSnackBar.error(
          context,
          'Limite da Google API atingido. Tente novamente mais tarde.',
        );
        return;
      case LocationServiceErrorCode.requestFailed:
        AppSnackBar.error(context, error.message);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(onboardingFormProvider);
    final selectedAddress = formState.resolvedAddress;
    final currentLocationLabel =
        widget.initialLocationLabel ?? formState.initialLocationLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Qual seu endereco?',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge.copyWith(
            fontSize: 32,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'Vamos usar essa localizacao para conectar voce com oportunidades proximas.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.s32),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: selectedAddress == null
              ? _buildChooserState(currentLocationLabel)
              : _buildSelectedState(selectedAddress),
        ),
      ],
    );
  }

  Widget _buildChooserState(String? currentLocationLabel) {
    final actionsEnabled = LocationService.isConfigured;

    return OnboardingSectionCard(
      key: const ValueKey('address-chooser-state'),
      title: 'Escolha como adicionar',
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FullWidthSelectionCard(
            icon: Icons.my_location,
            title: _isLoadingLocation
                ? 'Obtendo localizacao...'
                : 'Usar localizacao atual',
            description:
                currentLocationLabel ?? 'Encontrar meu endereco pelo GPS',
            isSelected: false,
            onTap: _useCurrentLocation,
            isEnabled: actionsEnabled && !_isLoadingLocation,
            trailing: _isLoadingLocation
                ? const AppLoadingIndicator.small(color: AppColors.primary)
                : const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.s24),
          const OrDivider(text: 'Ou'),
          const SizedBox(height: AppSpacing.s24),
          FullWidthSelectionCard(
            icon: Icons.search,
            title: 'Buscar endereco',
            description: 'Toque para abrir a busca e digitar seu endereco',
            isSelected: false,
            onTap: _openSearch,
            isEnabled: actionsEnabled,
            trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          if (!actionsEnabled) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Servico indisponivel. Configure a chave da Google API para continuar.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedState(ResolvedAddress address) {
    return OnboardingSectionCard(
      key: const ValueKey('address-selected-state'),
      title: 'Revise no mapa para finalizar',
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: AppRadius.all16,
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.titleLine,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (address.subtitleLine.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          address.subtitleLine,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          AppButton.outline(
            text: 'Alterar endereco',
            size: AppButtonSize.large,
            isFullWidth: true,
            onPressed: _openSearch,
          ),
          const SizedBox(height: AppSpacing.s12),
          AppButton.primary(
            text: 'Revisar no mapa e finalizar',
            size: AppButtonSize.large,
            isFullWidth: true,
            onPressed: () => _reviewAndFinish(address),
          ),
        ],
      ),
    );
  }
}
