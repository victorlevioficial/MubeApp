import 'package:flutter/foundation.dart';

import 'matchpoint_action_result.dart';
import 'matchpoint_swipe_command.dart';

enum MatchpointSwipeCommandStatus { accepted, processed }

@immutable
class MatchpointSwipeCommandResult {
  final String targetUserId;
  final MatchpointSwipeAction action;
  final MatchpointSwipeCommandStatus status;
  final String? commandId;
  final bool isMatch;
  final String? matchId;
  final String? conversationId;
  final int? remainingLikes;
  final String? message;

  const MatchpointSwipeCommandResult({
    required this.targetUserId,
    required this.action,
    required this.status,
    this.commandId,
    this.isMatch = false,
    this.matchId,
    this.conversationId,
    this.remainingLikes,
    this.message,
  });

  bool get isQueued => status == MatchpointSwipeCommandStatus.accepted;
  bool get isProcessed => status == MatchpointSwipeCommandStatus.processed;

  factory MatchpointSwipeCommandResult.fromLegacyAction({
    required MatchpointSwipeCommand command,
    required MatchpointActionResult actionResult,
  }) {
    return MatchpointSwipeCommandResult(
      targetUserId: command.targetUserId,
      action: command.action,
      status: MatchpointSwipeCommandStatus.processed,
      isMatch: actionResult.isMatch,
      matchId: actionResult.matchId,
      conversationId: actionResult.conversationId,
      remainingLikes: actionResult.remainingLikes,
      message: actionResult.message,
    );
  }
}
