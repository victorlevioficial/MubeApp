import 'package:freezed_annotation/freezed_annotation.dart';

enum ApplicationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('rejected')
  rejected,
  @JsonValue('gig_cancelled')
  gigCancelled;

  String get label {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pendente';
      case ApplicationStatus.accepted:
        return 'Aceita';
      case ApplicationStatus.rejected:
        return 'Recusada';
      case ApplicationStatus.gigCancelled:
        return 'Gig cancelada';
    }
  }
}
