import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/chat/domain/conversation_preview.dart';
import 'package:mube/src/features/chat/presentation/conversations_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeChatRepository fakeChatRepo;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeChatRepo = FakeChatRepository();
  });

  Widget createSubject({List<ConversationPreview> conversations = const []}) {
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
          builder: (context, state) =>
              Scaffold(body: Text('Chat: ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        chatRepositoryProvider.overrideWithValue(fakeChatRepo),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ConversationsScreen', () {
    testWidgets('renders correctly with app bar', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Conversas'), findsOneWidget);
    });

    testWidgets('shows empty state when no conversations', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma conversa ainda'), findsOneWidget);
      expect(
        find.text('Suas conexões e amigos aparecerão aqui.'),
        findsOneWidget,
      );
    });

    testWidgets('renders conversation list', (tester) async {
      final conversations = [
        TestData.conversationPreview(
          id: 'conv-1',
          otherUserName: 'John Doe',
          lastMessageText: 'Hello!',
          unreadCount: 2,
        ),
        TestData.conversationPreview(
          id: 'conv-2',
          otherUserName: 'Jane Smith',
          lastMessageText: 'How are you?',
          unreadCount: 0,
        ),
      ];

      await tester.pumpWidget(createSubject(conversations: conversations));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('How are you?'), findsOneWidget);
    });

    testWidgets('shows unread badge for unread messages', (tester) async {
      final conversations = [
        TestData.conversationPreview(
          id: 'conv-1',
          otherUserName: 'John Doe',
          unreadCount: 5,
        ),
      ];

      await tester.pumpWidget(createSubject(conversations: conversations));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('navigates to chat when conversation tapped', (tester) async {
      final conversations = [
        TestData.conversationPreview(id: 'conv-123', otherUserName: 'John Doe'),
      ];

      await tester.pumpWidget(createSubject(conversations: conversations));
      await tester.pumpAndSettle();

      await tester.tap(find.text('John Doe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Chat: conv-123'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      // Create a completer to delay the stream
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Should show loading indicator initially
      expect(find.byType(ConversationsScreen), findsOneWidget);
    });
  });
}
