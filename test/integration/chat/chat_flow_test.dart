import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/chat/data/chat_providers.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/chat/domain/conversation_preview.dart';
import 'package:mube/src/features/chat/presentation/conversations_screen.dart';

import '../../helpers/firebase_test_config.dart';
import '../../helpers/test_data.dart';
import '../../helpers/test_fakes.dart';

/// Integration tests for the chat feature.
///
/// Wraps `ConversationsScreen` in the full app surface (GoRouter +
/// MaterialApp.router) so navigation assertions exercise the real router
/// stack, unlike the widget-level tests which only verify rendering.
///
/// Coverage:
/// - Empty state when the user has no conversations.
/// - Conversation list renders with preview text for the other user.
/// - Tapping a conversation routes to the chat screen for that id.
void main() {
  setUpAll(() async => await setupFirebaseCoreMocks());

  group('Chat Flow Integration Tests', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeChatRepository fakeChatRepo;

    setUp(() {
      fakeAuthRepo = FakeAuthRepository();
      fakeChatRepo = FakeChatRepository();
      scaffoldMessengerKey.currentState?.clearSnackBars();
    });

    tearDown(() {
      fakeAuthRepo.dispose();
    });

    Future<void> pumpConversationsApp(
      WidgetTester tester, {
      List<ConversationPreview> conversations = const [],
      AsyncValue<List<ConversationPreview>>? acceptedConversationsAsync,
      AsyncValue<List<ConversationPreview>>? pendingConversationsAsync,
    }) async {
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepo.appUser = user;
      fakeChatRepo.setConversations(conversations);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: '/conversation/:id',
            builder: (context, state) => Scaffold(
              body: Text('Chat: ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(user),
            ),
            chatRepositoryProvider.overrideWithValue(fakeChatRepo),
            if (acceptedConversationsAsync != null)
              userAcceptedConversationsProvider.overrideWithValue(
                acceptedConversationsAsync,
              ),
            if (pendingConversationsAsync != null)
              userPendingConversationsProvider.overrideWithValue(
                pendingConversationsAsync,
              ),
          ],
          child: MaterialApp.router(
            scaffoldMessengerKey: scaffoldMessengerKey,
            routerConfig: router,
            theme: ThemeData.dark(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows empty state when user has no conversations', (
      tester,
    ) async {
      await pumpConversationsApp(
        tester,
        acceptedConversationsAsync: const AsyncValue.data([]),
      );

      expect(find.byType(ConversationsScreen), findsOneWidget);
      expect(find.text('Nenhuma conversa ainda'), findsOneWidget);
    });

    testWidgets('lists an existing conversation with preview', (tester) async {
      final conversations = [
        TestData.conversationPreview(
          id: 'conv-1',
          otherUserId: 'user-2',
          otherUserName: 'John Doe',
          lastMessageText: 'Hello there!',
          unreadCount: 1,
        ),
      ];

      await pumpConversationsApp(tester, conversations: conversations);

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Hello there!'), findsOneWidget);
    });

    testWidgets('tapping a conversation navigates to ChatScreen', (
      tester,
    ) async {
      final conversations = [
        TestData.conversationPreview(
          id: 'conv-1',
          otherUserId: 'user-2',
          otherUserName: 'John Doe',
          lastMessageText: 'Hello there!',
        ),
      ];

      await pumpConversationsApp(tester, conversations: conversations);

      expect(find.text('John Doe'), findsOneWidget);

      await tester.tap(find.text('John Doe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Chat: conv-1'), findsOneWidget);
    });
  });
}
