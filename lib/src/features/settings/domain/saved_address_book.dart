import '../../auth/domain/app_user.dart';
import 'saved_address.dart';

abstract final class SavedAddressBook {
  static const int maxAddresses = 5;

  static List<SavedAddress> effectiveAddresses(AppUser user) {
    final addresses = user.addresses.isNotEmpty
        ? user.addresses
        : (user.location != null
              ? [SavedAddress.fromLocationMap(user.location!)]
              : const <SavedAddress>[]);
    return sortAndNormalize(addresses);
  }

  static List<SavedAddress> sortAndNormalize(List<SavedAddress> addresses) {
    if (addresses.isEmpty) return const [];

    validateLimit(addresses);

    final normalized = addresses.toList(growable: false);
    final primaryIndex = normalized.indexWhere((address) => address.isPrimary);
    final effectivePrimaryIndex = primaryIndex >= 0 ? primaryIndex : 0;

    final result = <SavedAddress>[];
    for (var index = 0; index < normalized.length; index++) {
      final address = normalized[index];
      result.add(address.copyWith(isPrimary: index == effectivePrimaryIndex));
    }

    result.sort((a, b) {
      if (a.isPrimary == b.isPrimary) return 0;
      return a.isPrimary ? -1 : 1;
    });
    return result;
  }

  static void validateLimit(List<SavedAddress> addresses) {
    if (addresses.length > maxAddresses) {
      throw StateError('Limite de $maxAddresses enderecos atingido.');
    }
  }

  static List<SavedAddress> addAsPrimary(
    List<SavedAddress> addresses,
    SavedAddress newAddress,
  ) {
    validateLimit([...addresses, newAddress]);
    final updated = [
      ...addresses.map((address) => address.copyWith(isPrimary: false)),
      newAddress.copyWith(isPrimary: true),
    ];
    return sortAndNormalize(updated);
  }

  static List<SavedAddress> setPrimary(
    List<SavedAddress> addresses,
    SavedAddress address,
  ) {
    final updated = addresses.map((item) {
      return item.copyWith(isPrimary: item.id == address.id);
    }).toList();
    return sortAndNormalize(updated);
  }

  static List<SavedAddress> delete(
    List<SavedAddress> addresses,
    SavedAddress address,
  ) {
    if (addresses.length <= 1) {
      throw StateError('Pelo menos 1 endereco deve permanecer salvo.');
    }

    final updated = addresses.where((item) => item.id != address.id).toList();
    if (updated.isEmpty) return const [];
    return sortAndNormalize(updated);
  }

  static AppUser syncUser(AppUser user, List<SavedAddress> addresses) {
    final normalized = sortAndNormalize(addresses);
    final primary = normalized.isEmpty ? null : normalized.first;
    return user.copyWith(
      addresses: normalized,
      location: primary?.toLocationMap(),
    );
  }
}
