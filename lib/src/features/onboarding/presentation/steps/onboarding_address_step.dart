import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/utils/app_logger.dart';

import '../../../../common_widgets/location_service.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/inputs/app_autocomplete_field.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/patterns/or_divider.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../onboarding_form_provider.dart';

class OnboardingAddressStep extends ConsumerStatefulWidget {
  final Future<void> Function() onNext;
  final VoidCallback onBack;

  const OnboardingAddressStep({
    super.key,
    required this.onNext,
    required this.onBack,
    this.initialLocationLabel,
  });

  final String? initialLocationLabel;

  @override
  ConsumerState<OnboardingAddressStep> createState() =>
      _OnboardingAddressStepState();
}

class _OnboardingAddressStepState extends ConsumerState<OnboardingAddressStep> {
  final _locationService = LocationService();
  Timer? _debounce;

  final _searchController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoadingLocation = false;
  bool _isLoadingPreview = false;
  bool _isLoadingSearch = false;
  bool _isResolvingManual = false;
  bool _addressFound = false;

  double? _selectedLat;
  double? _selectedLng;
  String? _currentLocationLabel;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);

    _cepController.text = formState.cep ?? '';
    _logradouroController.text = formState.logradouro ?? '';
    _numeroController.text = formState.numero ?? '';
    _bairroController.text = formState.bairro ?? '';
    _cidadeController.text = formState.cidade ?? '';
    _estadoController.text = formState.estado ?? '';
    _selectedLat = formState.selectedLat;
    _selectedLng = formState.selectedLng;

    if (_logradouroController.text.isNotEmpty) {
      _addressFound = true;
      _searchController.text = _buildAddressSummary();
    }

    _currentLocationLabel = widget.initialLocationLabel;
    if (_currentLocationLabel == null) {
      _fetchCurrentLocationPreview();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocationPreview() async {
    if (!mounted) return;
    setState(() => _isLoadingPreview = true);

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) return;

      final details = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (details != null && mounted) {
        setState(() {
          _currentLocationLabel = _buildLocationLabel(details);
        });
      }
    } catch (e, st) {
      AppLogger.warning(
        'Falha ao obter preview de localização no onboarding',
        e,
        st,
      );
    } finally {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    final normalized = query.trim();
    if (normalized.length < 3) {
      setState(() {
        _searchResults = [];
        _isLoadingSearch = false;
      });
      return;
    }

    setState(() => _isLoadingSearch = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _locationService.searchAddress(normalized);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    });
  }

  Future<void> _selectAddress(Map<String, dynamic> item) async {
    if (_isResolvingManual) return;

    setState(() => _isResolvingManual = true);
    try {
      final placeId = item['place_id']?.toString();
      final description = (item['description'] ?? '').toString();
      final numberHint = (item['number_hint'] ?? description).toString();

      Map<String, dynamic>? details;
      if (placeId != null && placeId.isNotEmpty) {
        details = await _locationService.getPlaceDetails(placeId);
      }
      details ??= await _locationService.resolveAddressFromQuery(description);

      if (details == null) {
        if (mounted) {
          AppSnackBar.error(
            context,
            'Não foi possível obter esse endereço. Tente outro resultado.',
          );
        }
        return;
      }

      final enriched = _applyNumberHint(details, numberHint);
      _fillAddressFields(enriched);
      _persistAddress(lat: _selectedLat, lng: _selectedLng);

      if (!mounted) return;
      setState(() {
        _addressFound = true;
        _searchResults = [];
        _searchController.text = description.isNotEmpty
            ? description
            : _buildAddressSummary();
      });
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e, st) {
      AppLogger.error('Falha ao selecionar endereço', e, st);
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao carregar endereço. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isResolvingManual = false);
    }
  }

  Future<void> _resolveTypedAddress() async {
    final query = _searchController.text.trim();
    if (query.length < 5 || _isResolvingManual) return;

    setState(() {
      _isResolvingManual = true;
      _searchResults = [];
    });

    try {
      final details = await _locationService.resolveAddressFromQuery(query);
      if (details == null) {
        if (mounted) {
          AppSnackBar.error(
            context,
            'Endereço não encontrado. Inclua rua, número e cidade.',
          );
        }
        return;
      }

      final enriched = _applyNumberHint(details, query);
      _fillAddressFields(enriched);
      _persistAddress(lat: _selectedLat, lng: _selectedLng);

      if (!mounted) return;
      setState(() => _addressFound = true);
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e, st) {
      AppLogger.error('Falha ao buscar endereço digitado', e, st);
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao buscar endereço. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isResolvingManual = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          AppSnackBar.error(context, 'Não foi possível obter localização.');
        }
        return;
      }

      final details = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (details == null) {
        if (mounted) {
          AppSnackBar.error(context, 'Endereço não encontrado.');
        }
        return;
      }

      _fillAddressFields(details);
      _persistAddress(lat: _selectedLat, lng: _selectedLng);

      if (!mounted) return;
      setState(() {
        _addressFound = true;
        _currentLocationLabel = _buildLocationLabel(details);
        _searchController.text = _buildAddressSummary();
      });
    } catch (e, st) {
      AppLogger.error('Erro ao obter localização no onboarding', e, st);
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao obter localização: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Map<String, dynamic> _applyNumberHint(
    Map<String, dynamic> address,
    String hintSource,
  ) {
    final result = Map<String, dynamic>.from(address);
    final current = (result['numero'] ?? '').toString().trim();
    if (current.isNotEmpty) return result;

    final extracted = _extractHouseNumber(hintSource);
    if (extracted.isNotEmpty) {
      result['numero'] = extracted;
    }
    return result;
  }

  String _extractHouseNumber(String source) {
    final head = source.split(',').take(2).join(' ');
    final match = RegExp(r'\b\d{1,6}[A-Za-z0-9\-\/]*\b').firstMatch(head);
    return match?.group(0) ?? '';
  }

  void _fillAddressFields(Map<String, dynamic> address) {
    _logradouroController.text = (address['logradouro'] ?? '').toString().trim();
    _numeroController.text = (address['numero'] ?? '').toString().trim();
    _bairroController.text = (address['bairro'] ?? '').toString().trim();
    _cidadeController.text = (address['cidade'] ?? '').toString().trim();
    _estadoController.text = (address['estado'] ?? '').toString().trim();
    _cepController.text = (address['cep'] ?? '').toString().trim();

    final lat = address['lat'];
    final lng = address['lng'];
    if (lat is num) _selectedLat = lat.toDouble();
    if (lng is num) _selectedLng = lng.toDouble();
  }

  String _buildLocationLabel(Map<String, dynamic> details) {
    final street = (details['logradouro'] ?? '').toString();
    final number = (details['numero'] ?? '').toString();
    final mainStreet = [street, number]
        .where((value) => value.trim().isNotEmpty)
        .join(', ');

    final chunks = <String>[
      mainStreet,
      (details['bairro'] ?? '').toString(),
      (details['cidade'] ?? '').toString(),
    ].where((value) => value.trim().isNotEmpty).toList();

    if (chunks.isEmpty) return 'Localização atual';
    return chunks.join(' - ');
  }

  String _buildAddressSummary() {
    final street = _logradouroController.text.trim();
    final number = _numeroController.text.trim();
    final bairro = _bairroController.text.trim();
    final cidade = _cidadeController.text.trim();
    final estado = _estadoController.text.trim();

    final streetLine = [street, number]
        .where((value) => value.isNotEmpty)
        .join(', ');

    final parts = <String>[
      streetLine,
      bairro,
      [cidade, estado].where((value) => value.isNotEmpty).join(' - '),
    ].where((value) => value.trim().isNotEmpty).toList();

    return parts.join(' • ');
  }

  void _persistAddress({double? lat, double? lng}) {
    _selectedLat = lat ?? _selectedLat;
    _selectedLng = lng ?? _selectedLng;

    ref
        .read(onboardingFormProvider.notifier)
        .updateAddress(
          cep: _cepController.text.trim(),
          logradouro: _logradouroController.text.trim(),
          numero: _numeroController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          lat: _selectedLat,
          lng: _selectedLng,
        );
  }

  bool _validateBeforeFinish() {
    if (_logradouroController.text.trim().isEmpty) {
      AppSnackBar.warning(context, 'Informe o logradouro.');
      return false;
    }
    if (_numeroController.text.trim().isEmpty) {
      AppSnackBar.warning(context, 'Informe o número (ou "s/n").');
      return false;
    }
    if (_cidadeController.text.trim().isEmpty) {
      AppSnackBar.warning(context, 'Informe a cidade.');
      return false;
    }
    if (_estadoController.text.trim().isEmpty) {
      AppSnackBar.warning(context, 'Informe o estado.');
      return false;
    }
    return true;
  }

  Future<void> _finishStep() async {
    if (!_validateBeforeFinish()) return;
    _persistAddress();
    await widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
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
          duration: const Duration(milliseconds: 250),
          child: _addressFound ? _buildConfirmState() : _buildSearchState(),
        ),
      ],
    );
  }

  Widget _buildSearchState() {
    return Column(
      key: const ValueKey('address-search-state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLocationButton(),
        const SizedBox(height: AppSpacing.s24),
        const OrDivider(text: 'Ou'),
        const SizedBox(height: AppSpacing.s24),
        AppAutocompleteField<Map<String, dynamic>>(
          controller: _searchController,
          label: 'Buscar Endereço',
          hint: 'Ex: Rua Augusta, 1500, São Paulo',
          prefixIcon: const Icon(Icons.search, size: 20),
          options: _searchResults,
          isLoading: _isLoadingSearch,
          onChanged: (value) {
            _onSearchChanged(value);
            if (mounted) setState(() {});
          },
          displayStringForOption: (item) =>
              (item['description'] ?? '').toString(),
          onSelected: _selectAddress,
          itemBuilder: (context, item) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s4,
              ),
              leading: const Icon(Icons.location_on_outlined, size: 20),
              title: Text(
                (item['description'] ?? '').toString().split(',').first.trim(),
              ),
              subtitle: Text(
                (item['description'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Dica: inclua número e cidade para melhorar a precisão.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s20),
        SizedBox(
          height: 56,
          child: AppButton.primary(
            text: 'Confirmar endereço digitado',
            size: AppButtonSize.large,
            isLoading: _isResolvingManual,
            onPressed: _searchController.text.trim().length < 5
                ? null
                : _resolveTypedAddress,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmState() {
    return Column(
      key: const ValueKey('address-confirm-state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: AppRadius.all16,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  _buildAddressSummary(),
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        AppTextField(
          controller: _logradouroController,
          label: 'Logradouro',
          hint: 'Rua / Avenida',
          prefixIcon: const Icon(Icons.route_outlined, size: 20),
          onChanged: (_) => _persistAddress(),
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _numeroController,
                label: 'Número',
                hint: 'Ex: 123',
                keyboardType: TextInputType.streetAddress,
                prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                onChanged: (_) => _persistAddress(),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: AppTextField(
                controller: _cepController,
                label: 'CEP',
                hint: 'Ex: 01310-100',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.markunread_mailbox_outlined, size: 20),
                onChanged: (_) => _persistAddress(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        AppTextField(
          controller: _bairroController,
          label: 'Bairro',
          hint: 'Seu bairro',
          prefixIcon: const Icon(Icons.map_outlined, size: 20),
          onChanged: (_) => _persistAddress(),
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _cidadeController,
                label: 'Cidade',
                hint: 'Sua cidade',
                prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                onChanged: (_) => _persistAddress(),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: AppTextField(
                controller: _estadoController,
                label: 'Estado',
                hint: 'UF',
                textCapitalization: TextCapitalization.characters,
                prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                onChanged: (_) => _persistAddress(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        SizedBox(
          height: 56,
          child: AppButton.outline(
            text: 'Buscar novamente',
            size: AppButtonSize.large,
            onPressed: () {
              setState(() {
                _addressFound = false;
                _searchController.text = _buildAddressSummary();
              });
            },
            isFullWidth: true,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 56,
          child: AppButton.primary(
            text: 'Finalizar',
            size: AppButtonSize.large,
            onPressed: _finishStep,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationButton() {
    return InkWell(
      onTap: _isLoadingLocation ? null : _useCurrentLocation,
      borderRadius: AppRadius.all12,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: AppRadius.all12,
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.s40,
              height: AppSpacing.s40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: AppSpacing.s24,
                      height: AppSpacing.s24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                      size: AppSpacing.s24,
                    ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoadingLocation
                        ? 'Obtendo localização...'
                        : 'Usar minha localização atual',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (_isLoadingPreview)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s4),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: AppSpacing.s12,
                            height: AppSpacing.s12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Text(
                            'Carregando prévia...',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_currentLocationLabel != null) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      _currentLocationLabel!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
