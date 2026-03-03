import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../common_widgets/location_service.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../domain/resolved_address.dart';

class AddressConfirmScreen extends StatefulWidget {
  const AddressConfirmScreen({
    super.key,
    required this.initialAddress,
    this.confirmButtonText = 'Confirmar endereco',
    this.onConfirmed,
  });

  final ResolvedAddress initialAddress;
  final String confirmButtonText;
  final Future<bool> Function(ResolvedAddress address)? onConfirmed;

  @override
  State<AddressConfirmScreen> createState() => _AddressConfirmScreenState();
}

class _AddressConfirmScreenState extends State<AddressConfirmScreen> {
  late final TextEditingController _numberController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.initialAddress.numero);
    _numberController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  ResolvedAddress get _currentAddress =>
      widget.initialAddress.copyWith(numero: _numberController.text.trim());

  Future<void> _handleConfirm() async {
    final currentAddress = _currentAddress;
    if (!currentAddress.canConfirm || _isSubmitting) {
      return;
    }

    if (widget.onConfirmed == null) {
      Navigator.of(context).pop(currentAddress);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await widget.onConfirmed!(currentAddress);
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop(currentAddress);
      } else {
        setState(() => _isSubmitting = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAddress = _currentAddress;
    final blockingReason = currentAddress.confirmBlockingReason;
    final canConfirm = currentAddress.canConfirm && !_isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(
        title: 'Confirmar endereco',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StaticMapPreview(address: currentAddress),
              const SizedBox(height: AppSpacing.s20),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.all16,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAddress.logradouro,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (currentAddress.subtitleLine.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        currentAddress.subtitleLine,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (currentAddress.cep.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'CEP: ${currentAddress.cep.trim()}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              AppTextField(
                controller: _numberController,
                label: 'Numero',
                hint: 'Ex: 1500',
                prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.done,
              ),
              if (blockingReason != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(
                  blockingReason,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s32),
              AppButton.primary(
                text: widget.confirmButtonText,
                size: AppButtonSize.large,
                isFullWidth: true,
                isLoading: _isSubmitting,
                onPressed: canConfirm ? _handleConfirm : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticMapPreview extends StatelessWidget {
  const _StaticMapPreview({required this.address});

  final ResolvedAddress address;

  @override
  Widget build(BuildContext context) {
    final canShowMap =
        address.lat != null &&
        address.lng != null &&
        LocationService.isConfigured;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all20,
        border: Border.all(color: AppColors.border),
        image: canShowMap
            ? DecorationImage(
                fit: BoxFit.cover,
                image: CachedNetworkImageProvider(
                  'https://maps.googleapis.com/maps/api/staticmap?center=${address.lat},${address.lng}&zoom=16&size=900x360&maptype=roadmap&markers=color:red%7C${address.lat},${address.lng}&key=${LocationService.googleApiKey}',
                ),
              )
            : null,
      ),
      child: canShowMap
          ? null
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Mapa indisponivel',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
