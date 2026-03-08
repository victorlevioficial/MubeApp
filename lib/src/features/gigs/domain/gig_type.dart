import 'package:freezed_annotation/freezed_annotation.dart';

enum GigType {
  @JsonValue('show_ao_vivo')
  liveShow,
  @JsonValue('evento_privado')
  privateEvent,
  @JsonValue('gravacao')
  recording,
  @JsonValue('ensaio_jam')
  rehearsalJam,
  @JsonValue('outro')
  other;

  String get label {
    switch (this) {
      case GigType.liveShow:
        return 'Show ao vivo';
      case GigType.privateEvent:
        return 'Evento privado';
      case GigType.recording:
        return 'Gravacao';
      case GigType.rehearsalJam:
        return 'Ensaio / Jam';
      case GigType.other:
        return 'Outro';
    }
  }
}
