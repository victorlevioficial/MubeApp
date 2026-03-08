// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      id: json['id'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      conversationId: json['conversationId'] as String?,
      senderId: json['senderId'] as String?,
      route: json['route'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'body': instance.body,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'route': instance.route,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.chatMessage: 'chat_message',
  NotificationType.bandInvite: 'band_invite',
  NotificationType.bandInviteAccepted: 'band_invite_accepted',
  NotificationType.gigApplication: 'gig_application',
  NotificationType.gigApplicationAccepted: 'gig_application_accepted',
  NotificationType.gigApplicationRejected: 'gig_application_rejected',
  NotificationType.gigCancelled: 'gig_cancelled',
  NotificationType.gigReviewReminder: 'gig_review_reminder',
  NotificationType.gigOpportunity: 'gig_opportunity',
  NotificationType.like: 'like',
  NotificationType.system: 'system',
};
