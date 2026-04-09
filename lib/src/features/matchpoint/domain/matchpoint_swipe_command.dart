import 'package:flutter/foundation.dart';

enum MatchpointSwipeAction { like, dislike }

extension MatchpointSwipeActionX on MatchpointSwipeAction {
  String get value {
    switch (this) {
      case MatchpointSwipeAction.like:
        return 'like';
      case MatchpointSwipeAction.dislike:
        return 'dislike';
    }
  }

  static MatchpointSwipeAction fromValue(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'dislike':
        return MatchpointSwipeAction.dislike;
      case 'like':
      default:
        return MatchpointSwipeAction.like;
    }
  }
}

@immutable
class MatchpointSwipeCommand {
  final String sourceUserId;
  final String targetUserId;
  final MatchpointSwipeAction action;
  final DateTime createdAt;
  final String? idempotencyKey;

  const MatchpointSwipeCommand({
    required this.sourceUserId,
    required this.targetUserId,
    required this.action,
    required this.createdAt,
    this.idempotencyKey,
  });

  MatchpointSwipeCommand copyWith({
    String? sourceUserId,
    String? targetUserId,
    MatchpointSwipeAction? action,
    DateTime? createdAt,
    String? idempotencyKey,
  }) {
    return MatchpointSwipeCommand(
      sourceUserId: sourceUserId ?? this.sourceUserId,
      targetUserId: targetUserId ?? this.targetUserId,
      action: action ?? this.action,
      createdAt: createdAt ?? this.createdAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceUserId': sourceUserId,
      'targetUserId': targetUserId,
      'action': action.value,
      'createdAt': createdAt.toIso8601String(),
      'idempotencyKey': idempotencyKey,
    };
  }

  factory MatchpointSwipeCommand.fromJson(Map<String, dynamic> json) {
    return MatchpointSwipeCommand(
      sourceUserId: json['sourceUserId'] as String? ?? '',
      targetUserId: json['targetUserId'] as String? ?? '',
      action: MatchpointSwipeActionX.fromValue(
        json['action'] as String? ?? 'like',
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }
}
