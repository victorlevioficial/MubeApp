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

part 'addresses_screen_ui.dart';

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
        loading: _buildLoadingState,
        error: (_, _) => _buildLoadErrorState(),
        data: _buildUserContent,
      ),
    );
  }
}
