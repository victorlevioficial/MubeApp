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
}

@immutable
class MatchpointSwipeCommand {
  final String targetUserId;
  final MatchpointSwipeAction action;
  final DateTime createdAt;
  final String? idempotencyKey;

  const MatchpointSwipeCommand({
    required this.targetUserId,
    required this.action,
    required this.createdAt,
    this.idempotencyKey,
  });
}
