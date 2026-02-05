import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_model.freezed.dart';
part 'ticket_model.g.dart';

@freezed
sealed class Ticket with _$Ticket {
  const factory Ticket({
    required String id,
    required String userId,
    required String title,
    required String description,
    required String category, // 'bug', 'feedback', 'account', 'other'
    required TicketStatus status,
    @Default([]) List<String> imageUrls,
    @Default(false) bool hasUnreadMessages,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Ticket;

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
}

enum TicketStatus {
  @JsonValue('open')
  open,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('resolved')
  resolved,
  @JsonValue('closed')
  closed;

  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Aberto';
      case TicketStatus.inProgress:
        return 'Em Análise';
      case TicketStatus.resolved:
        return 'Resolvido';
      case TicketStatus.closed:
        return 'Fechado';
    }
  }
}
