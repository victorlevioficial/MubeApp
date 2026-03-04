import 'dart:async';

import 'package:flutter/material.dart';

import '../../../common_widgets/location_service.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/components/patterns/full_width_selection_card.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../domain/address_search_result.dart';
import '../domain/resolved_address.dart';
import 'address_flow.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({
    super.key,
    this.confirmButtonText = 'Confirmar endereço',
    this.onConfirmAddress,
  });

  final String confirmButtonText;
  final Future<bool> Function(ResolvedAddress address)? onConfirmAddress;

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final _locationService = LocationService();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  List<AddressSearchResult> _results = const [];
  bool _isSearching = false;
  bool _isResolvingSelection = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _results = const [];
        _isSearching = false;
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _locationService.searchAddress(query);
        if (!mounted) return;
        setState(() {
          _results = results;
          _isSearching = false;
          _errorMessage = null;
        });
      } on LocationServiceException catch (error) {
        if (!mounted) return;
        setState(() {
          _results = const [];
          _isSearching = false;
          _errorMessage = _messageForSearchError(error);
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _results = const [];
          _isSearching = false;
          _errorMessage = 'Erro ao buscar endereços. Tente novamente.';
        });
      }
    });
  }

  Future<void> _selectResult(AddressSearchResult result) async {
    if (_isResolvingSelection) return;

    setState(() => _isResolvingSelection = true);
    try {
      final resolved = await _locationService.getPlaceDetails(
        result.placeId,
        numberHint: result.numberHint,
      );
      if (!mounted) return;
      if (resolved == null) {
        AppSnackBar.error(
          context,
          'Não foi possível obter detalhes desse endereço.',
        );
        return;
      }

      final confirmed = await showAddressConfirmScreen(
        context,
        resolved,
        confirmButtonText: widget.confirmButtonText,
        onConfirmed: widget.onConfirmAddress,
      );
      if (!mounted || confirmed == null) return;
      Navigator.of(context).pop<ResolvedAddress>(confirmed);
    } on LocationServiceException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, _messageForDetailsError(error));
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Não foi possível obter detalhes desse endereço.',
      );
    } finally {
      if (mounted) setState(() => _isResolvingSelection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Buscar endereço', showBackButton: true),
      body: SafeArea(
        child: AppLoadingOverlay(
          isLoading: _isResolvingSelection,
          message: 'Carregando endereço...',
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  label: 'Digite seu endereço',
                  hint: 'Ex: Rua Augusta, 1500, São Paulo',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  onChanged: _onSearchChanged,
                  readOnly: !LocationService.isConfigured,
                  canRequestFocus: LocationService.isConfigured,
                  textInputAction: TextInputAction.search,
                  errorText: !LocationService.isConfigured
                      ? 'Configure a chave da Google API para buscar endereços.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  'Inclua rua, número e cidade para resultados mais precisos.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!LocationService.isConfigured) {
      return const EmptyStateWidget(
        icon: Icons.warning_amber_rounded,
        title: 'Busca indisponível',
        subtitle:
            'Configure a chave da Google API para habilitar a busca de endereços.',
      );
    }

    if (_isSearching) {
      return const Center(
        child: AppLoadingIndicator.withMessage('Buscando endereços...'),
      );
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Não foi possível buscar',
        subtitle: _errorMessage!,
      );
    }

    if (!_hasSearched) {
      return const EmptyStateWidget(
        icon: Icons.location_on_outlined,
        title: 'Busque seu endereço',
        subtitle: 'Comece digitando para ver sugestões precisas da Google.',
      );
    }

    if (_results.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off_outlined,
        title: 'Nenhum endereço encontrado',
        subtitle: 'Tente incluir número e cidade para melhorar a busca.',
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        final result = _results[index];
        return FullWidthSelectionCard(
          icon: Icons.location_on_outlined,
          title: result.mainText,
          description: result.secondaryText,
          isSelected: false,
          onTap: () => _selectResult(result),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        );
      },
    );
  }

  String _messageForSearchError(LocationServiceException error) {
    switch (error.code) {
      case LocationServiceErrorCode.apiKeyMissing:
        return error.message;
      case LocationServiceErrorCode.quotaExceeded:
        return 'Limite da Google API atingido. Tente novamente mais tarde.';
      default:
        return 'Erro ao buscar endereços. Tente novamente.';
    }
  }

  String _messageForDetailsError(LocationServiceException error) {
    switch (error.code) {
      case LocationServiceErrorCode.apiKeyMissing:
        return error.message;
      case LocationServiceErrorCode.quotaExceeded:
        return 'Limite da Google API atingido. Tente novamente mais tarde.';
      default:
        return 'Não foi possível obter detalhes desse endereço.';
    }
  }
}
