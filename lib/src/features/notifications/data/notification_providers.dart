import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/notification_model.dart';
import 'notification_repository.dart';

export 'notification_repository.dart';

/// Stream de notificações do usuário atual.
/// Retorna lista vazia se não estiver logado.
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
      final user = ref.watch(currentUserProfileProvider).value;
      if (user == null) return Stream.value([]);

      return ref
          .read(notificationRepositoryProvider)
          .watchNotifications(user.uid);
    });

/// Contagem de notificações não lidas baseada no Firestore.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

/// Mantém compatibilidade com código legado que incrementa manualmente.
/// DEPRECATED: Use notificationsStreamProvider em vez disso.
final legacyUnreadCountProvider = NotifierProvider<LegacyUnreadNotifier, int>(
  LegacyUnreadNotifier.new,
);

class LegacyUnreadNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void reset() => state = 0;
}
