import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../common_widgets/location_service.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../../design_system/components/patterns/onboarding_section_card.dart';
import '../../../../design_system/components/patterns/or_divider.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';
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
      AppLogger.error(
        'Address search unavailable: GOOGLE_MAPS_API_KEY is not configured',
      );
      AppSnackBar.warning(
        context,
        'Não foi possível abrir a busca de endereço agora. Tente novamente em instantes.',
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
        'Não foi possível concluir o cadastro. Tente novamente.',
      );
      return false;
    }

    return true;
  }

  Future<void> _useCurrentLocation() async {
    if (_isLoadingLocation) return;
    if (!LocationService.isConfigured) {
      AppLogger.error(
        'Current location unavailable: GOOGLE_MAPS_API_KEY is not configured',
      );
      AppSnackBar.warning(
        context,
        'Não foi possível obter sua localização agora. Tente novamente em instantes.',
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
          'Não foi possível determinar o endereço da localização atual.',
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
        'Não foi possível obter sua localização atual.',
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
          'Permissão de localização negada permanentemente. Abra as configurações do dispositivo.',
        );
        await Geolocator.openAppSettings();
        return;
      case LocationServiceErrorCode.permissionDenied:
        AppSnackBar.warning(
          context,
          'Permissão de localização negada. Ative nas configurações do dispositivo.',
        );
        return;
      case LocationServiceErrorCode.serviceDisabled:
        AppSnackBar.warning(
          context,
          'GPS desativado. Ative o serviço de localização.',
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
          'Qual seu endereço?',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge.copyWith(
            fontSize: 32,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'Vamos usar essa localização para conectar você com oportunidades próximas.',
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
          _AddressActionTile(
            icon: Icons.my_location,
            title: _isLoadingLocation
                ? 'Obtendo localização...'
                : 'Usar localização atual',
            description:
                currentLocationLabel ?? 'Encontrar meu endereço pelo GPS',
            onTap: _useCurrentLocation,
            isEnabled: actionsEnabled && !_isLoadingLocation,
            trailing: _isLoadingLocation
                ? const AppLoadingIndicator.small(color: AppColors.primary)
                : const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.s16),
          const OrDivider(text: 'Ou'),
          const SizedBox(height: AppSpacing.s16),
          _AddressActionTile(
            icon: Icons.search,
            title: 'Buscar endereço',
            description: 'Toque para abrir a busca e digitar seu endereço',
            onTap: _openSearch,
            isEnabled: actionsEnabled,
            trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
          if (!actionsEnabled) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Busca de endereço indisponível no momento. Tente novamente em instantes.',
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
            text: 'Alterar endereço',
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

class _AddressActionTile extends StatelessWidget {
  const _AddressActionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.isEnabled,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isEnabled;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final tile = InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: AppRadius.all16,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppRadius.all16,
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            trailing,
          ],
        ),
      ),
    );

    if (isEnabled) return tile;
    return Opacity(opacity: 0.5, child: IgnorePointer(child: tile));
  }
}
