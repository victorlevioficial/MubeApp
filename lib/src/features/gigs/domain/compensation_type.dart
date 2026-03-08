import 'package:freezed_annotation/freezed_annotation.dart';

enum CompensationType {
  @JsonValue('fixed')
  fixed,
  @JsonValue('negotiable')
  negotiable,
  @JsonValue('volunteer')
  volunteer,
  @JsonValue('tbd')
  toBeDefined;

  String get label {
    switch (this) {
      case CompensationType.fixed:
        return 'Cache fixo';
      case CompensationType.negotiable:
        return 'A negociar';
      case CompensationType.volunteer:
        return 'Voluntario';
      case CompensationType.toBeDefined:
        return 'A definir';
    }
  }
}
