import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'saved_address.freezed.dart';
part 'saved_address.g.dart';

/// Represents a saved address in the user's address book.
/// Users can have up to 5 addresses, with one marked as primary.
@freezed
abstract class SavedAddress with _$SavedAddress {
  const factory SavedAddress({
    /// Unique identifier for this address.
    required String id,

    /// User-defined label (e.g., "Casa", "Trabalho").
    @Default('') String nome,

    /// Street name.
    @Default('') String logradouro,

    /// Street number.
    @Default('') String numero,

    /// Neighborhood.
    @Default('') String bairro,

    /// City name.
    @Default('') String cidade,

    /// State abbreviation (e.g., "SP").
    @Default('') String estado,

    /// Postal code.
    @Default('') String cep,

    /// Latitude coordinate.
    double? lat,

    /// Longitude coordinate.
    @JsonKey(name: 'long') double? lng,

    /// Whether this is the primary/active address.
    @Default(false) bool isPrimary,

    /// Creation timestamp.
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SavedAddress;

  factory SavedAddress.fromJson(Map<String, dynamic> json) =>
      _$SavedAddressFromJson(json);

  const SavedAddress._();

  /// Creates a new empty address with a generated ID.
  factory SavedAddress.empty() =>
      SavedAddress(id: const Uuid().v4(), createdAt: DateTime.now());

  /// Converts to the legacy location format for backward compatibility.
  Map<String, dynamic> toLocationMap() => {
    'logradouro': logradouro,
    'numero': numero,
    'bairro': bairro,
    'cidade': cidade,
    'estado': estado,
    'cep': cep,
    'lat': lat,
    'long': lng,
  };

  /// Creates from legacy location map format.
  factory SavedAddress.fromLocationMap(Map<String, dynamic> map) {
    return SavedAddress(
      id: const Uuid().v4(),
      logradouro: map['logradouro'] ?? '',
      numero: map['numero'] ?? '',
      bairro: map['bairro'] ?? '',
      cidade: map['cidade'] ?? '',
      estado: map['estado'] ?? '',
      cep: map['cep'] ?? '',
      lat: map['lat'] as double?,
      lng: map['long'] as double?,
      isPrimary: true,
      createdAt: DateTime.now(),
    );
  }

  /// Formatted display string for the address.
  String get displayAddress {
    final parts = <String>[];
    if (logradouro.isNotEmpty) {
      parts.add(numero.isNotEmpty ? '$logradouro, $numero' : logradouro);
    }
    if (bairro.isNotEmpty) parts.add(bairro);
    if (cidade.isNotEmpty) {
      parts.add(estado.isNotEmpty ? '$cidade - $estado' : cidade);
    }
    return parts.join(', ');
  }

  /// Short display for list items.
  String get shortDisplay {
    if (cidade.isNotEmpty && estado.isNotEmpty) {
      return '$cidade - $estado';
    }
    return cidade.isNotEmpty ? cidade : 'Endereço incompleto';
  }
}
