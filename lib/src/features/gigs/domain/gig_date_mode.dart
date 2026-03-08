import 'package:freezed_annotation/freezed_annotation.dart';

enum GigDateMode {
  @JsonValue('fixed_date')
  fixedDate,
  @JsonValue('to_be_arranged')
  toBeArranged,
  @JsonValue('unspecified')
  unspecified;

  String get label {
    switch (this) {
      case GigDateMode.fixedDate:
        return 'Data fixa';
      case GigDateMode.toBeArranged:
        return 'A combinar';
      case GigDateMode.unspecified:
        return 'Sem data';
    }
  }
}
