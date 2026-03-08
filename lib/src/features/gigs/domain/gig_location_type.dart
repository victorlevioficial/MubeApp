import 'package:freezed_annotation/freezed_annotation.dart';

enum GigLocationType {
  @JsonValue('presencial')
  onsite,
  @JsonValue('remoto')
  remote;

  String get label {
    switch (this) {
      case GigLocationType.onsite:
        return 'Presencial';
      case GigLocationType.remote:
        return 'Remoto';
    }
  }
}
