import 'package:freezed_annotation/freezed_annotation.dart';

enum ReviewType {
  @JsonValue('creator_to_participant')
  creatorToParticipant,
  @JsonValue('participant_to_creator')
  participantToCreator;

  String get label {
    switch (this) {
      case ReviewType.creatorToParticipant:
        return 'Criador para participante';
      case ReviewType.participantToCreator:
        return 'Participante para criador';
    }
  }
}
