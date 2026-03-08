import 'package:freezed_annotation/freezed_annotation.dart';

enum GigStatus {
  @JsonValue('open')
  open,
  @JsonValue('closed')
  closed,
  @JsonValue('expired')
  expired,
  @JsonValue('cancelled')
  cancelled;

  String get label {
    switch (this) {
      case GigStatus.open:
        return 'Aberta';
      case GigStatus.closed:
        return 'Fechada';
      case GigStatus.expired:
        return 'Expirada';
      case GigStatus.cancelled:
        return 'Cancelada';
    }
  }
}
