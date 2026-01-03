import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common_widgets/app_text_field.dart';
import '../../../../common_widgets/app_snackbar.dart';
import '../../../../common_widgets/primary_button.dart';
import '../../../../common_widgets/location_service.dart';
import '../onboarding_form_provider.dart';
import '../../../../common_widgets/or_divider.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';

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
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoadingLocation = false;
  bool _isLoadingPreview = false; // New state for initial preview
  bool _addressFound = false;

  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  // Local state for map preview
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

    if (widget.initialLocationLabel != null) {
      _currentLocationLabel = widget.initialLocationLabel;
    }

    if (_logradouroController.text.isNotEmpty) {
      _addressFound = true;
    }

    // Always ensure we have a preview label for the button, in case user clicks "Edit"
    if (_currentLocationLabel == null) {
      _fetchCurrentLocationPreview();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  // --- Logic copied from Contractor Flow ---

  Future<void> _fetchCurrentLocationPreview() async {
    if (!mounted) return;
    setState(() => _isLoadingPreview = true);

    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final details = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (details != null && mounted) {
          setState(() {
            _currentLocationLabel =
                '${details['logradouro']} - ${details['bairro']} - ${details['cidade']}';
          });
        }
      }
    } catch (_) {
      // Silent error for preview
    } finally {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _locationService.searchAddress(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    });
  }

  void _selectAddress(Map<String, dynamic> item) async {
    final placeId = item['place_id'];
    if (placeId != null) {
      final details = await _locationService.getPlaceDetails(placeId);
      if (details != null && mounted) {
        _fillAddressFields(details);
        setState(() {
          _addressFound = true;
          _searchResults = [];

          FocusManager.instance.primaryFocus?.unfocus();
        });
        _persistAddress(lat: details['lat'], lng: details['lng']);
      } else {
        if (mounted)
          AppSnackBar.show(context, 'Erro ao obter detalhes.', isError: true);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final details = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (details != null) {
          _fillAddressFields(details);
          setState(() {
            _currentLocationLabel =
                '${details['logradouro']} - ${details['bairro']} - ${details['cidade']}';
            _addressFound = true;
          });
          _persistAddress(lat: details['lat'], lng: details['lng']);
        } else {
          if (mounted)
            AppSnackBar.show(
              context,
              'Endereço não encontrado.',
              isError: true,
            );
        }
      } else {
        if (mounted)
          AppSnackBar.show(
            context,
            'Não foi possível obter localização.',
            isError: true,
          );
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Erro: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _fillAddressFields(Map<String, dynamic> address) {
    _logradouroController.text = address['logradouro'] ?? '';
    _numeroController.text = address['numero'] ?? '';
    _bairroController.text = address['bairro'] ?? '';
    _cidadeController.text = address['cidade'] ?? '';
    _estadoController.text = address['estado'] ?? '';
    _cepController.text = address['cep'] ?? '';
  }

  void _persistAddress({double? lat, double? lng}) {
    _selectedLat = lat ?? _selectedLat;
    _selectedLng = lng ?? _selectedLng;

    ref
        .read(onboardingFormProvider.notifier)
        .updateAddress(
          cep: _cepController.text,
          logradouro: _logradouroController.text,
          numero: _numeroController.text,
          bairro: _bairroController.text,
          cidade: _cidadeController.text,
          estado: _estadoController.text,
          lat: _selectedLat,
          lng: _selectedLng,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          'Qual seu endereço?',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Para encontrarmos as melhores conexões perto de você.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s32),

        if (!_addressFound) ...[
          // 1. Use My Location Button (Top)
          InkWell(
            onTap: _isLoadingLocation ? null : _useCurrentLocation,
            borderRadius: BorderRadius.circular(AppSpacing.s12),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.s12),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.s40,
                    height: AppSpacing.s40,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _isLoadingLocation
                        ? SizedBox(
                            width: AppSpacing.s20,
                            height: AppSpacing.s20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.my_location,
                            color: Theme.of(context).colorScheme.primary,
                            size: AppSpacing.s20,
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        if (_isLoadingPreview)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: AppSpacing.s12,
                                  height: AppSpacing.s12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s8),
                                Text(
                                  'Carregando prévia...',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.s24),
          const OrDivider(text: 'Ou'),
          const SizedBox(height: AppSpacing.s24),

          // 2. Search Field (Now directly on background for consistency)
          AppTextField(
            controller: _logradouroController,
            label: 'Buscar Endereço',
            hint: 'Digitar endereço manual...',
            prefixIcon: const Icon(Icons.search),
            onChanged: (val) {
              _onSearchChanged(val);
              setState(() {});
            },
          ),

          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: AppSpacing.s8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s4,
                    ),
                    leading: const Icon(Icons.location_on_outlined, size: 20),
                    title: Text(item['description']?.split(',')[0] ?? ''),
                    subtitle: Text(
                      item['description'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => _selectAddress(item),
                  );
                },
              ),
            ),

          const SizedBox(height: AppSpacing.s16),
          PrimaryButton(
            text: 'Buscar Manualmente',
            onPressed: _logradouroController.text.length > 3
                ? () => setState(() => _addressFound = true)
                : null,
          ),
        ] else ...[
          // Confirm Mode
          Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
              image: DecorationImage(
                image: NetworkImage(
                  'https://maps.googleapis.com/maps/api/staticmap?center=${_selectedLat ?? -23.55},${_selectedLng ?? -46.63}&zoom=15&size=600x300&maptype=roadmap&markers=color:red%7C${_selectedLat},${_selectedLng}&key=${LocationService.googleApiKey}',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ajustar no mapa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Address Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_logradouroController.text}, ${_numeroController.text}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_bairroController.text}, ${_cidadeController.text} - ${_estadoController.text}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  setState(() {
                    _addressFound = false;
                    // Ideally we don't clear everything, just allow edit
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s48),
          const SizedBox(height: AppSpacing.s48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: PrimaryButton(
              text: 'Finalizar',
              onPressed: () {
                _persistAddress();
                widget.onNext();
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
