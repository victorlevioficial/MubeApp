import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/chat/domain/conversation_preview.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/notifications/domain/notification_model.dart';
import 'package:mube/src/features/support/domain/ticket_model.dart';

/// Centralized test data factory to avoid duplication across tests.
abstract final class TestData {
  // ─── AppUser ────────────────────────────────────────────────────────

  static AppUser user({
    String uid = 'test-user-id',
    String email = 'test@example.com',
    String nome = 'Test User',
    String cadastroStatus = 'concluido',
    AppUserType? tipoPerfil = AppUserType.professional,
    String status = 'ativo',
    String? bio,
    String? foto,
    Map<String, dynamic>? location,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      nome: nome,
      cadastroStatus: cadastroStatus,
      tipoPerfil: tipoPerfil,
      status: status,
      bio: bio ?? 'Test bio',
      foto: foto,
      location:
          location ??
          {
            'cidade': 'São Paulo',
            'estado': 'SP',
            'lat': -23.5505,
            'lng': -46.6333,
          },
    );
  }

  static AppUser pendingUser({String uid = 'pending-user'}) =>
      user(uid: uid, cadastroStatus: 'tipo_pendente', tipoPerfil: null);

  static AppUser bandUser({String uid = 'band-user'}) =>
      user(uid: uid, nome: 'Test Band', tipoPerfil: AppUserType.band);

  // ─── FeedItem ───────────────────────────────────────────────────────

  static FeedItem feedItem({
    String id = 'feed-item-1',
    String nome = 'Feed User',
    String? foto,
    String tipoPerfil = 'profissional',
    double? distanceKm,
  }) {
    return FeedItem(
      uid: id,
      nome: nome,
      foto: foto,
      tipoPerfil: tipoPerfil,
      distanceKm: distanceKm ?? 2.5,
    );
  }

  static List<FeedItem> feedItems(int count) => List.generate(
    count,
    (i) => feedItem(id: 'feed-item-$i', nome: 'User $i'),
  );

  // ─── AppNotification ───────────────────────────────────────────────

  static AppNotification notification({
    String id = 'notif-1',
    NotificationType type = NotificationType.like,
    String title = 'New notification',
    String body = 'Someone liked your profile',
    bool isRead = false,
    DateTime? createdAt,
    String? conversationId,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead,
      createdAt: createdAt ?? DateTime(2025, 1, 1),
      conversationId: conversationId,
    );
  }

  static List<AppNotification> notifications(int count) => List.generate(
    count,
    (i) => notification(
      id: 'notif-$i',
      title: 'Notification $i',
      isRead: i.isEven,
    ),
  );

  // ─── Ticket ─────────────────────────────────────────────────────────

  static Ticket ticket({
    String id = 'ticket-1',
    String userId = 'test-user-id',
    String title = 'Test Ticket',
    String description = 'Something went wrong',
    String category = 'bug',
    TicketStatus status = TicketStatus.open,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime(2025, 1, 1);
    return Ticket(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      status: status,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  static List<Ticket> tickets(int count) => List.generate(
    count,
    (i) => ticket(
      id: 'ticket-$i',
      title: 'Ticket $i',
      status: TicketStatus.values[i % TicketStatus.values.length],
    ),
  );

  // ─── ConversationPreview ────────────────────────────────────────────

  static ConversationPreview conversationPreview({
    String id = 'conv-1',
    String otherUserId = 'other-user',
    String otherUserName = 'Other User',
    String? lastMessageText = 'Hello!',
    int unreadCount = 0,
  }) {
    return ConversationPreview(
      id: id,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      lastMessageText: lastMessageText,
      unreadCount: unreadCount,
      updatedAt: Timestamp.fromDate(DateTime(2025, 1, 1)),
    );
  }

  static List<ConversationPreview> conversations(int count) => List.generate(
    count,
    (i) => conversationPreview(
      id: 'conv-$i',
      otherUserId: 'user-$i',
      otherUserName: 'User $i',
    ),
  );
}
