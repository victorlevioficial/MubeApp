import 'package:flutter/material.dart';

import '../domain/resolved_address.dart';
import 'address_confirm_screen.dart';
import 'address_search_screen.dart';

Future<ResolvedAddress?> showAddressSearchScreen(
  BuildContext context, {
  String confirmButtonText = 'Confirmar endereço',
  Future<bool> Function(ResolvedAddress address)? onConfirmAddress,
}) {
  return Navigator.of(context).push<ResolvedAddress>(
    MaterialPageRoute(
      builder: (_) => AddressSearchScreen(
        confirmButtonText: confirmButtonText,
        onConfirmAddress: onConfirmAddress,
      ),
    ),
  );
}

Future<ResolvedAddress?> showAddressConfirmScreen(
  BuildContext context,
  ResolvedAddress address, {
  String confirmButtonText = 'Confirmar endereço',
  Future<bool> Function(ResolvedAddress address)? onConfirmed,
}) {
  return Navigator.of(context).push<ResolvedAddress>(
    MaterialPageRoute(
      builder: (_) => AddressConfirmScreen(
        initialAddress: address,
        confirmButtonText: confirmButtonText,
        onConfirmed: onConfirmed,
      ),
    ),
  );
}
