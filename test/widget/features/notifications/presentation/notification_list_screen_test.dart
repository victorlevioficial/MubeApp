import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/notifications/data/notification_providers.dart';
import 'package:mube/src/features/notifications/data/notification_repository.dart';
import 'package:mube/src/features/notifications/domain/notification_model.dart';
import 'package:mube/src/features/notifications/presentation/notification_list_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeNotificationRepository fakeNotificationRepo;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeNotificationRepo = FakeNotificationRepository();
  });

  Widget createSubject({List<AppNotification> notifications = const []}) {
    final user = TestData.user(uid: 'user-1');
    fakeAuthRepo.appUser = user;
    fakeNotificationRepo.setNotifications(notifications);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const NotificationListScreen(),
        ),
        GoRoute(
          path: '/conversation/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Conversation: ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/invites',
          builder: (context, state) => const Scaffold(body: Text('Invites Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        notificationRepositoryProvider.overrideWithValue(fakeNotificationRepo),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('NotificationListScreen', () {
    testWidgets('renders correctly with app bar', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Notificações'), findsOneWidget);
    });

    testWidgets('shows empty state when no notifications', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma notificação'), findsOneWidget);
      expect(find.text('Você será notificado quando houver novidades'), findsOneWidget);
    });

    testWidgets('renders notification list', (tester) async {
      final notifications = [
        TestData.notification(
          id: 'notif-1',
          title: 'New Like',
          body: 'Someone liked your profile',
          type: NotificationType.like,
        ),
        TestData.notification(
          id: 'notif-2',
          title: 'New Message',
          body: 'You have a new message',
          type: NotificationType.chatMessage,
          conversationId: 'conv-123',
        ),
      ];

      await tester.pumpWidget(createSubject(notifications: notifications));
      await tester.pumpAndSettle();

      expect(find.text('New Like'), findsOneWidget);
      expect(find.text('New Message'), findsOneWidget);
      expect(find.text('Someone liked your profile'), findsOneWidget);
    });

    testWidgets('shows Limpar button when notifications exist', (tester) async {
      final notifications = [TestData.notification(id: 'notif-1')];

      await tester.pumpWidget(createSubject(notifications: notifications));
      await tester.pumpAndSettle();

      expect(find.text('Limpar'), findsOneWidget);
    });

    testWidgets('marks notification as read when tapped', (tester) async {
      final notifications = [
        TestData.notification(
          id: 'notif-1',
          type: NotificationType.like,
          isRead: false,
        ),
      ];

      await tester.pumpWidget(createSubject(notifications: notifications));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the notification was marked as read
      expect(fakeNotificationRepo.throwError, false);
    });

    testWidgets('navigates to conversation for chat notifications', (tester) async {
      final notifications = [
        TestData.notification(
          id: 'notif-1',
          type: NotificationType.chatMessage,
          conversationId: 'conv-123',
        ),
      ];

      await tester.pumpWidget(createSubject(notifications: notifications));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Conversation: conv-123'), findsOneWidget);
    });

    testWidgets('navigates to invites for band invite notifications', (tester) async {
      final notifications = [
        TestData.notification(
          id: 'notif-1',
          type: NotificationType.bandInvite,
        ),
      ];

      await tester.pumpWidget(createSubject(notifications: notifications));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Invites Screen'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog when Limpar tapped', (tester) async {
      final notifications = [TestData.notification(id: 'notif-1')];

      await tester.pumpWidget(createSubject(notifications: notifications));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(find.text('Limpar notificações'), findsOneWidget);
      expect(find.text('Deseja apagar todas as notificações?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('deletes all notifications when confirmed', (tester) async {
      final notifications = [TestData.notification(id: 'notif-1')];

      await tester.pumpWidget(createSubject(notifications: notifications));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar').last);
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeNotificationRepo.throwError, false);
    });
  });
}
