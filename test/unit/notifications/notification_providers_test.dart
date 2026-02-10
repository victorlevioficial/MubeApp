import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/notifications/data/notification_providers.dart';
import 'package:mube/src/features/notifications/domain/notification_model.dart';

@GenerateNiceMocks([
  MockSpec<NotificationRepository>(),
  MockSpec<AuthRepository>(),
])
import 'notification_providers_test.mocks.dart';

class MockUserNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;
  set user(AppUser? value) => state = value;
}

final mockUserProvider = NotifierProvider<MockUserNotifier, AppUser?>(
  MockUserNotifier.new,
);

void main() {
  late ProviderContainer container;
  late MockNotificationRepository mockRepo;
  late MockAuthRepository mockAuthRepo;
  late StreamController<List<AppNotification>>
  notificationController; // Removed MockUser

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockRepo = MockNotificationRepository();
    // mockUser removed
    notificationController =
        StreamController<List<AppNotification>>.broadcast();

    // Stub watchNotifications to return our controller stream
    when(
      mockRepo.watchNotifications(any),
    ).thenAnswer((_) => notificationController.stream);

    container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(mockRepo),
        // Override currentUserProfileProvider to return a value we control
        currentUserProfileProvider.overrideWith((ref) {
          return mockAuthRepo.watchUser(null);
        }),
      ],
    );

    // Default mock setup
    when(mockAuthRepo.watchUser(any)).thenAnswer(
      (_) => Stream.value(
        const AppUser(
          uid: 'user123',
          email: 'test@example.com',
          nome: 'Test',
          foto: 'photo.jpg',
        ),
      ),
    );

    // Keep providers alive
    container.listen(currentUserProfileProvider, (previous, next) {});
    container.listen(notificationsStreamProvider, (previous, next) {});
  });

  tearDown(() {
    notificationController.close();
    container.dispose();
  });

  group('notificationsStreamProvider', () {
    test('should return empty list when user is null', () async {
      // Arrange
      when(mockAuthRepo.watchUser(any)).thenAnswer((_) => Stream.value(null));
      container.refresh(currentUserProfileProvider);

      // Act
      final value = await container.read(notificationsStreamProvider.future);

      // Assert
      expect(value, isEmpty);
      verifyNever(mockRepo.watchNotifications(any));
    });

    test('should emit empty list when user is null', () async {
      // Arrange: User is null
      when(mockAuthRepo.watchUser(any)).thenAnswer((_) => Stream.value(null));
      container.refresh(currentUserProfileProvider);

      // Act
      final value = await container.read(notificationsStreamProvider.future);

      // Assert
      expect(value, isEmpty);
    });

    test('should emit notifications from repository', () async {
      // Arrange
      final notifications = [
        AppNotification(
          id: '1',
          title: 'Test',
          body: 'Body',
          createdAt: DateTime.now(),
          isRead: false,
          type: NotificationType.like,
        ),
      ];

      // Act
      final future = container.read(notificationsStreamProvider.future);
      await Future.delayed(Duration.zero);
      notificationController.add(notifications);

      // Assert
      expect(await future, notifications);
    });

    test('should subscribe to repository when user is logged in', () async {
      // Arrange
      const user = AppUser(
        uid: 'user1',
        email: 'test@example.com',
        nome: 'Test',
        foto: 'photo.jpg',
      );
      when(mockAuthRepo.watchUser(any)).thenAnswer((_) => Stream.value(user));
      container.refresh(currentUserProfileProvider);

      final notifications = [
        AppNotification(
          id: '1',
          type: NotificationType.system,
          title: 'Test',
          body: 'Msg',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];

      await Future.delayed(Duration.zero);
      notificationController.add(notifications);

      // Act
      final value = await container.read(notificationsStreamProvider.future);

      // Assert
      expect(value, notifications);
      verify(mockRepo.watchNotifications('user1')).called(1);
    });
  });

  group('unreadNotificationCountProvider', () {
    test('should return 0 when list is empty', () {
      // Arrange
      when(mockAuthRepo.watchUser(any)).thenAnswer((_) => Stream.value(null));
      container.refresh(currentUserProfileProvider);

      // Act
      final count = container.read(unreadNotificationCountProvider);

      // Assert
      expect(count, 0);
    });

    test('should count only unread notifications', () async {
      // Arrange
      const user = AppUser(
        uid: 'user1',
        email: 'test@example.com',
        nome: 'Test',
        foto: 'photo.jpg',
      );
      when(mockAuthRepo.watchUser(any)).thenAnswer((_) => Stream.value(user));
      container.refresh(currentUserProfileProvider); // Force refresh

      final notifications = [
        AppNotification(
          id: '1',
          type: NotificationType.system,
          title: 'Read',
          body: 'Msg',
          createdAt: DateTime.now(),
          isRead: true,
        ),
        AppNotification(
          id: '2',
          type: NotificationType.system,
          title: 'Unread 1',
          body: 'Msg',
          createdAt: DateTime.now(),
          isRead: false,
        ),
        AppNotification(
          id: '3',
          type: NotificationType.system,
          title: 'Unread 2',
          body: 'Msg',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];

      final completer = Completer<void>();

      container.listen(notificationsStreamProvider, (previous, next) {
        if (next.hasValue && next.value?.length == 3) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      // Wait for user to be loaded
      await container.read(currentUserProfileProvider.future);
      // Allow provider to subscribe to the new stream source
      await Future.delayed(Duration.zero);

      notificationController.add(notifications);

      // Wait for stream to emit populated list
      await completer.future;

      // Allow propagation
      await Future.delayed(Duration.zero);

      // Act
      final count = container.read(unreadNotificationCountProvider);

      // Assert
      expect(count, 2);
    });
  });
}
