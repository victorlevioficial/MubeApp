import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/notifications/data/notification_providers.dart';
import 'package:mube/src/features/notifications/domain/notification_model.dart';

import '../../helpers/test_fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeNotificationRepository fakeNotificationRepository;

  const loggedUser = AppUser(
    uid: 'user-1',
    email: 'test@example.com',
    nome: 'Test User',
    foto: 'photo.jpg',
  );

  AppNotification buildNotification({
    required String id,
    required bool isRead,
  }) {
    return AppNotification(
      id: id,
      type: NotificationType.system,
      title: 'Titulo',
      body: 'Corpo',
      isRead: isRead,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  ProviderContainer buildContainer({
    required Stream<AppUser?> userStream,
  }) {
    return ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(
          fakeNotificationRepository,
        ),
        currentUserProfileProvider.overrideWith((ref) => userStream),
      ],
    );
  }

  Future<int> readUnreadCount(ProviderContainer container) {
    final completer = Completer<int>();
    late final ProviderSubscription<AsyncValue<int>> subscription;

    subscription = container.listen<AsyncValue<int>>(
      unreadNotificationCountStreamProvider,
      (previous, next) {
        if (next.hasValue && !completer.isCompleted) {
          completer.complete(next.value!);
          subscription.close();
        }
      },
      fireImmediately: true,
    );

    return completer.future;
  }

  setUp(() {
    fakeNotificationRepository = FakeNotificationRepository();
    container = buildContainer(userStream: Stream.value(loggedUser));
  });

  tearDown(() {
    container.dispose();
  });

  group('unreadNotificationCountStreamProvider', () {
    test('returns zero when user is null without touching notifications list', (
      ) async {
      container.dispose();
      container = buildContainer(userStream: Stream.value(null));

      final value = await readUnreadCount(container);

      expect(value, 0);
      expect(container.read(unreadNotificationCountProvider), 0);
      expect(fakeNotificationRepository.watchUnreadNotificationCountCalls, 0);
      expect(fakeNotificationRepository.watchNotificationsCalls, 0);
    });

    test('emits the exact unread count even above the visible notifications cap', (
      ) async {
      final notifications = <AppNotification>[
        ...List.generate(
          51,
          (index) => buildNotification(id: 'unread-$index', isRead: false),
        ),
        ...List.generate(
          9,
          (index) => buildNotification(id: 'read-$index', isRead: true),
        ),
      ];
      fakeNotificationRepository.setNotifications(notifications);

      final value = await readUnreadCount(container);

      expect(value, 51);
      expect(container.read(unreadNotificationCountProvider), 51);
      expect(fakeNotificationRepository.watchUnreadNotificationCountCalls, 1);
      expect(fakeNotificationRepository.watchNotificationsCalls, 0);
    });
  });
}
