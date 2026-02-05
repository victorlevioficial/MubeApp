import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/saved_address.dart';
import 'widgets/address_card.dart';

/// Screen for managing multiple saved addresses.
class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  static const int _maxAddresses = 5;

  List<SavedAddress> get _addresses {
    final user = ref.watch(currentUserProfileProvider).value;
    if (user == null) return [];

    List<SavedAddress> addresses;

    // If user has no addresses but has legacy location, migrate it
    if (user.addresses.isEmpty && user.location != null) {
      final legacyAddress = SavedAddress.fromLocationMap(user.location!);
      addresses = [legacyAddress];
    } else {
      addresses = user.addresses.toList();
    }

    // Sort so primary is always at the top
    addresses.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return 0;
    });

    return addresses;
  }

  Future<void> _saveAddresses(List<SavedAddress> addresses) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    // Find primary address to sync with legacy location field
    final primary = addresses.firstWhere(
      (a) => a.isPrimary,
      orElse: () =>
          addresses.isNotEmpty ? addresses.first : SavedAddress.empty(),
    );

    final updatedUser = user.copyWith(
      addresses: addresses,
      location: primary.toLocationMap(),
    );

    await ref.read(authRepositoryProvider).updateUser(updatedUser);
  }

  void _addAddress() {
    if (_addresses.length >= _maxAddresses) {
      AppSnackBar.warning(
        context,
        'Limite de $_maxAddresses endereços atingido',
      );
      return;
    }
    context.push('/settings/address');
  }

  void _editAddress(SavedAddress address) {
    context.push('/settings/address', extra: address);
  }

  Future<void> _setAsPrimary(SavedAddress address) async {
    final updatedList = _addresses.map((a) {
      return a.copyWith(isPrimary: a.id == address.id);
    }).toList();

    await _saveAddresses(updatedList);
    if (mounted) {
      AppSnackBar.success(context, 'Endereço principal atualizado');
    }
  }

  Future<void> _deleteAddress(SavedAddress address) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: 'Excluir endereço?',
        message:
            'Deseja excluir "${address.nome.isNotEmpty ? address.nome : 'este endereço'}"?',
        confirmText: 'Excluir',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    var updatedList = _addresses.where((a) => a.id != address.id).toList();

    // If deleted was primary, make first remaining address primary
    if (address.isPrimary && updatedList.isNotEmpty) {
      updatedList = [
        updatedList.first.copyWith(isPrimary: true),
        ...updatedList.skip(1),
      ];
    }

    await _saveAddresses(updatedList);
    if (mounted) {
      AppSnackBar.success(context, 'Endereço excluído');
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = _addresses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Meus Endereços'),
      body: addresses.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: addresses.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return AddressCard(
                  address: address,
                  onTap: () => _editAddress(address),
                  onSetPrimary: () => _setAsPrimary(address),
                  onDelete: () => _deleteAddress(address),
                );
              },
            ),
      floatingActionButton: addresses.length < _maxAddresses
          ? FloatingActionButton.extended(
              onPressed: _addAddress,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Nenhum endereço salvo',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Adicione um endereço para aparecer\nna seção "Perto de mim"',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            ElevatedButton.icon(
              onPressed: _addAddress,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Endereço'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
