import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// Types of notifications supported by the app.
enum NotificationType {
  @JsonValue('chat_message')
  chatMessage,
  @JsonValue('band_invite')
  bandInvite,
  @JsonValue('like')
  like,
  @JsonValue('system')
  system,
}

/// A notification stored in Firestore.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    String? conversationId,
    String? senderId,
    @Default(false) bool isRead,
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  /// Creates an [AppNotification] from a Firestore document.
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: _parseType(data['type'] as String?),
      title: data['title'] as String? ?? 'Notificação',
      body: data['body'] as String? ?? '',
      conversationId: data['conversationId'] as String?,
      senderId: data['senderId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Helper to parse notification type string.
  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'chat_message':
        return NotificationType.chatMessage;
      case 'band_invite':
        return NotificationType.bandInvite;
      case 'like':
        return NotificationType.like;
      default:
        return NotificationType.system;
    }
  }
}

/// Extension for adding helper methods to AppNotification.
extension AppNotificationX on AppNotification {
  /// Returns the appropriate icon for this notification type.
  String get iconName {
    switch (type) {
      case NotificationType.chatMessage:
        return 'chat_bubble_outline';
      case NotificationType.bandInvite:
        return 'group_add';
      case NotificationType.like:
        return 'favorite_border';
      case NotificationType.system:
        return 'notifications_outlined';
    }
  }
}
