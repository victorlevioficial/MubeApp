import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final user = _readCurrentUser();
    if (user == null) {
      throw StateError(l10n.settings_addresses_session_expired_exception);
    }

    SavedAddressBook.validateLimit(addresses);
    final normalized = SavedAddressBook.sortAndNormalize(addresses);

    if (normalized.isNotEmpty) {
      final primary = normalized.first;
      if (primary.lat == null || primary.lng == null) {
        throw StateError(l10n.settings_addresses_primary_missing_coordinates);
      }
      if (primary.cidade.trim().isEmpty || primary.estado.trim().isEmpty) {
        throw StateError(l10n.settings_addresses_primary_missing_city_state);
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
    final l10n = AppLocalizations.of(context)!;
    final addresses = _readAddresses();
    if (addresses.length >= SavedAddressBook.maxAddresses) {
      AppSnackBar.warning(
        context,
        l10n.settings_addresses_limit_warning(
          SavedAddressBook.maxAddresses.toString(),
        ),
      );
      return;
    }
    if (!LocationService.isConfigured) {
      AppSnackBar.warning(
        context,
        l10n.settings_addresses_search_service_unavailable,
      );
      return;
    }

    final selectedAddress = await showAddressSearchScreen(context);
    if (!mounted || selectedAddress == null) return;

    await _persistNewAddress(selectedAddress);
  }

  Future<void> _persistNewAddress(ResolvedAddress selectedAddress) async {
    final l10n = AppLocalizations.of(context)!;
    if (!selectedAddress.canConfirm) {
      AppSnackBar.warning(
        context,
        selectedAddress.confirmBlockingReason ??
            l10n.settings_addresses_invalid_selection,
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
        successMessage: l10n.settings_addresses_add_success,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        l10n.settings_addresses_save_error(error.toString()),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isUsingCurrentLocation) return;

    final addresses = _readAddresses();
    if (addresses.length >= SavedAddressBook.maxAddresses) {
      AppSnackBar.warning(
        context,
        l10n.settings_addresses_limit_warning(
          SavedAddressBook.maxAddresses.toString(),
        ),
      );
      return;
    }
    if (!LocationService.isConfigured) {
      AppSnackBar.warning(
        context,
        l10n.settings_addresses_search_service_unavailable,
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
          l10n.settings_addresses_current_location_unavailable,
        );
        return;
      }

      final confirmed = await showAddressConfirmScreen(
        context,
        resolved,
        confirmButtonText: l10n.settings_addresses_confirm_current_location,
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
        l10n.settings_addresses_current_location_error(error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _isUsingCurrentLocation = false);
      }
    }
  }

  String _messageForLocationError(LocationServiceException error) {
    final l10n = AppLocalizations.of(context)!;
    switch (error.code) {
      case LocationServiceErrorCode.permissionDenied:
        return l10n.settings_addresses_permission_denied;
      case LocationServiceErrorCode.permissionDeniedForever:
        return l10n.settings_addresses_permission_denied_forever;
      case LocationServiceErrorCode.serviceDisabled:
        return l10n.settings_addresses_service_disabled;
      case LocationServiceErrorCode.apiKeyMissing:
        return error.message;
      case LocationServiceErrorCode.quotaExceeded:
        return l10n.settings_addresses_api_quota_exceeded;
      case LocationServiceErrorCode.requestFailed:
        return error.message;
    }
  }

  Future<void> _setAsPrimary(SavedAddress address) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _saveAddresses(
        SavedAddressBook.setPrimary(_readAddresses(), address),
        successMessage: l10n.settings_addresses_primary_updated,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        l10n.settings_addresses_update_error(error.toString()),
      );
    }
  }

  Future<void> _deleteAddress(SavedAddress address) async {
    final l10n = AppLocalizations.of(context)!;
    if (_readAddresses().length <= 1) {
      AppSnackBar.warning(context, l10n.settings_addresses_minimum_one_warning);
      return;
    }

    final confirmed = await AppOverlay.dialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: l10n.settings_addresses_delete_confirm_title,
        message: l10n.settings_addresses_delete_confirm_message,
        confirmText: l10n.common_delete,
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    try {
      await _saveAddresses(
        SavedAddressBook.delete(_readAddresses(), address),
        successMessage: l10n.settings_addresses_delete_success,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        l10n.settings_addresses_delete_error(error.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: l10n.settings_addresses),
      body: userAsync.when(
        loading: _buildLoadingState,
        error: (_, _) => _buildLoadErrorState(),
        data: _buildUserContent,
      ),
    );
  }
}
