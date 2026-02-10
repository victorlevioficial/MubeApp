import 'package:mube/src/features/auth/domain/app_user.dart';

/// Modelo de Match para a camada de domínio.
class MatchInfo {
  final String id;
  final String otherUserId;
  final AppUser? otherUser;
  final String? conversationId;
  final DateTime createdAt;

  MatchInfo({
    required this.id,
    required this.otherUserId,
    this.otherUser,
    this.conversationId,
    required this.createdAt,
  });
}
