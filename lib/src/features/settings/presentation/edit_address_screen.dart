import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../common_widgets/app_snackbar.dart';
import '../../../common_widgets/app_text_field.dart';
import '../../../common_widgets/location_service.dart';
import '../../../common_widgets/mube_app_bar.dart';
import '../../../common_widgets/or_divider.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/saved_address.dart';

/// Screen for editing user address/location - identical to onboarding flow.
class EditAddressScreen extends ConsumerStatefulWidget {
  final SavedAddress? existingAddress;

  const EditAddressScreen({super.key, this.existingAddress});

  @override
  ConsumerState<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends ConsumerState<EditAddressScreen> {
  final _locationService = LocationService();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoadingLocation = false;
  bool _isLoadingPreview = false;
  bool _addressFound = false;
  bool _isSaving = false;

  late String _addressId;
  final _nomeController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  double? _selectedLat;
  double? _selectedLng;
  String? _currentLocationLabel;

  bool get _isEditing => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    _addressId = widget.existingAddress?.id ?? const Uuid().v4();
    _loadExistingAddress();
    _fetchCurrentLocationPreview();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nomeController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _loadExistingAddress() {
    final address = widget.existingAddress;
    if (address != null) {
      // Editing existing address
      _nomeController.text = address.nome;
      _cepController.text = address.cep;
      _logradouroController.text = address.logradouro;
      _numeroController.text = address.numero;
      _bairroController.text = address.bairro;
      _cidadeController.text = address.cidade;
      _estadoController.text = address.estado;
      _selectedLat = address.lat;
      _selectedLng = address.lng;

      if (_logradouroController.text.isNotEmpty) {
        _addressFound = true;
      }
    }
  }

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
        setState(() => _searchResults = results);
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
      } else {
        if (mounted) {
          AppSnackBar.error(context, 'Erro ao obter detalhes.');
        }
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
        } else {
          if (mounted) {
            AppSnackBar.error(context, 'Endereço não encontrado.');
          }
        }
      } else {
        if (mounted) {
          AppSnackBar.error(context, 'Não foi possível obter localização.');
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Erro: $e');
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
    _selectedLat = address['lat'] as double?;
    _selectedLng = address['lng'] as double?;
  }

  Future<void> _saveAddress() async {
    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProfileProvider).value;
      if (user == null) return;

      // Get existing addresses (including legacy migration)
      List<SavedAddress> existingAddresses = user.addresses.toList();
      if (existingAddresses.isEmpty && user.location != null) {
        // Migrate legacy location to addresses list
        final legacyAddress = SavedAddress.fromLocationMap(user.location!);
        existingAddresses = [legacyAddress];
      }

      // New address is always primary, so remove isPrimary from others
      if (!_isEditing) {
        existingAddresses = existingAddresses.map((a) {
          return a.copyWith(isPrimary: false);
        }).toList();
      }

      final newAddress = SavedAddress(
        id: _addressId,
        nome: _nomeController.text.trim(),
        cep: _cepController.text.trim(),
        logradouro: _logradouroController.text.trim(),
        numero: _numeroController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        estado: _estadoController.text.trim(),
        lat: _selectedLat,
        lng: _selectedLng,
        // New address is always primary; editing keeps existing value
        isPrimary: _isEditing ? widget.existingAddress!.isPrimary : true,
        createdAt: _isEditing
            ? widget.existingAddress!.createdAt
            : DateTime.now(),
      );

      List<SavedAddress> updatedAddresses;
      if (_isEditing) {
        // Replace existing address
        updatedAddresses = existingAddresses.map((a) {
          return a.id == _addressId ? newAddress : a;
        }).toList();
      } else {
        // Add new address to the list
        updatedAddresses = [...existingAddresses, newAddress];
      }

      // Find primary to sync with legacy location
      final primary = updatedAddresses.firstWhere(
        (a) => a.isPrimary,
        orElse: () => updatedAddresses.first,
      );

      final updatedUser = user.copyWith(
        addresses: updatedAddresses,
        location: primary.toLocationMap(),
      );
      await ref.read(authRepositoryProvider).updateUser(updatedUser);

      if (mounted) {
        AppSnackBar.success(
          context,
          _isEditing ? 'Endereço atualizado!' : 'Endereço adicionado!',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao salvar: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MubeAppBar(
        title: _isEditing ? 'Editar Endereço' : 'Novo Endereço',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
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
                // Use My Location Button
                _buildLocationButton(),
                const SizedBox(height: AppSpacing.s24),
                const OrDivider(text: 'Ou'),
                const SizedBox(height: AppSpacing.s24),

                // Search Field
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

                if (_searchResults.isNotEmpty) _buildSearchResults(),

                const SizedBox(height: AppSpacing.s16),
                PrimaryButton(
                  text: 'Buscar Manualmente',
                  onPressed: _logradouroController.text.length > 3
                      ? () => setState(() => _addressFound = true)
                      : null,
                ),
              ] else ...[
                // Confirm Mode with Map Preview
                // Nome field (address label)
                AppTextField(
                  controller: _nomeController,
                  label: 'Nome do Endereço',
                  hint: 'Ex: Casa, Trabalho, Estúdio...',
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                const SizedBox(height: AppSpacing.s16),
                _buildMapPreview(),
                _buildAddressDetails(),
                const SizedBox(height: AppSpacing.s48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: PrimaryButton(
                    text: _isSaving ? 'Salvando...' : 'Salvar Endereço',
                    onPressed: _isSaving ? null : _saveAddress,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return InkWell(
      onTap: _isLoadingLocation ? null : _useCurrentLocation,
      borderRadius: BorderRadius.circular(AppSpacing.s12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.s12),
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
                      width: AppSpacing.s20,
                      height: AppSpacing.s20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
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
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
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

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
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
              style: AppTypography.bodySmall,
            ),
            onTap: () => _selectAddress(item),
          );
        },
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 150,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.s16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
        image: (_selectedLat != null && _selectedLng != null)
            ? DecorationImage(
                image: CachedNetworkImageProvider(
                  'https://maps.googleapis.com/maps/api/staticmap?center=$_selectedLat,$_selectedLng&zoom=15&size=600x300&maptype=roadmap&markers=color:red%7C$_selectedLat,$_selectedLng&key=${LocationService.googleApiKey}',
                ),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (_selectedLat == null)
              const Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ajustar no mapa',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_logradouroController.text}, ${_numeroController.text}',
                style: AppTypography.titleMedium.copyWith(
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
          onPressed: () => setState(() => _addressFound = false),
        ),
      ],
    );
  }
}
