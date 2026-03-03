import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';

@immutable
class AddressSearchResult {
  const AddressSearchResult({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.numberHint = '',
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final String numberHint;

  bool get hasNumberHint => numberHint.trim().isNotEmpty;

  String get normalizedMainText => normalizeForDedupe(mainText);

  AddressSearchResult copyWith({
    String? placeId,
    String? description,
    String? mainText,
    String? secondaryText,
    String? numberHint,
  }) {
    return AddressSearchResult(
      placeId: placeId ?? this.placeId,
      description: description ?? this.description,
      mainText: mainText ?? this.mainText,
      secondaryText: secondaryText ?? this.secondaryText,
      numberHint: numberHint ?? this.numberHint,
    );
  }

  static String normalizeForDedupe(String input) {
    final normalized = removeDiacritics(input).toLowerCase().trim();
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressSearchResult &&
        other.placeId == placeId &&
        other.description == description &&
        other.mainText == mainText &&
        other.secondaryText == secondaryText &&
        other.numberHint == numberHint;
  }

  @override
  int get hashCode => Object.hash(
    placeId,
    description,
    mainText,
    secondaryText,
    numberHint,
  );
}
