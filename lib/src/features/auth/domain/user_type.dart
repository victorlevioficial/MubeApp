import 'package:freezed_annotation/freezed_annotation.dart';

enum AppUserType {
  @JsonValue('profissional')
  professional,

  @JsonValue('estudio')
  studio,

  @JsonValue('banda')
  band,

  @JsonValue('contratante')
  contractor;

  String get label {
    switch (this) {
      case AppUserType.professional:
        return 'Profissional';
      case AppUserType.studio:
        return 'Estúdio';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.contractor:
        return 'Contratante';
    }
  }

  String get id {
    switch (this) {
      case AppUserType.professional:
        return 'profissional';
      case AppUserType.studio:
        return 'estudio';
      case AppUserType.band:
        return 'banda';
      case AppUserType.contractor:
        return 'contratante';
    }
  }
}
