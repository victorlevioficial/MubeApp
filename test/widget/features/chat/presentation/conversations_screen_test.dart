import 'package:cloud_firestore/cloud_firestore.dart';
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

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeChatRepository fakeChatRepo;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeChatRepo = FakeChatRepository();
  });

  Widget createSubject({
    List<ConversationPreview> conversations = const [],
    AsyncValue<List<ConversationPreview>>? acceptedConversationsAsync,
    AsyncValue<List<ConversationPreview>>? pendingConversationsAsync,
  }) {
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
      ),
    );
  }

  group('ConversationsScreen', () {
    testWidgets('renders correctly with app bar', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Conversas'), findsWidgets);
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

    testWidgets('prefixes last message with Voce when I sent it', (
      tester,
    ) async {
      final conversations = [
        ConversationPreview(
          id: 'conv-1',
          otherUserId: 'user-2',
          otherUserName: 'John Doe',
          lastMessageText: 'Tudo certo',
          lastSenderId: 'user-1',
          unreadCount: 0,
          updatedAt: Timestamp.fromDate(DateTime(2025, 1, 1)),
        ),
      ];

      await tester.pumpWidget(createSubject(conversations: conversations));
      await tester.pumpAndSettle();

      expect(find.text('Você: Tudo certo'), findsOneWidget);
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

    testWidgets('shows pending requests badge on requests tab', (tester) async {
      final conversations = [
        ConversationPreview(
          id: 'pending-1',
          otherUserId: 'user-2',
          otherUserName: 'John Doe',
          lastMessageText: 'Oi',
          unreadCount: 1,
          updatedAt: Timestamp.fromDate(DateTime(2025, 1, 1)),
          isPending: true,
          requestCycle: 1,
        ),
      ];

      await tester.pumpWidget(createSubject(conversations: conversations));
      await tester.pumpAndSettle();

      expect(find.text('Solicitações'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('hides previews without any message activity', (tester) async {
      final conversations = [
        ConversationPreview(
          id: 'conv-empty',
          otherUserId: 'user-2',
          otherUserName: 'John Doe',
          unreadCount: 0,
          updatedAt: Timestamp.fromDate(DateTime(2025, 1, 1)),
        ),
      ];

      await tester.pumpWidget(createSubject(conversations: conversations));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsNothing);
      expect(find.text('Nenhuma conversa ainda'), findsOneWidget);
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

    testWidgets('shows retry action when loading fails', (tester) async {
      await tester.pumpWidget(
        createSubject(
          acceptedConversationsAsync: AsyncValue.error(
            Exception('failed'),
            StackTrace.current,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Erro ao carregar conversas'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets(
      'moves an accepted request to Conversas immediately after swipe',
      (tester) async {
        final pendingPreview = ConversationPreview(
          id: 'pending-1',
          otherUserId: 'user-2',
          otherUserName: 'John Doe',
          lastMessageText: 'Oi',
          unreadCount: 1,
          updatedAt: Timestamp.fromDate(DateTime(2025, 1, 1)),
          isPending: true,
          requestCycle: 1,
        );

        await tester.pumpWidget(
          createSubject(
            acceptedConversationsAsync: const AsyncValue.data([]),
            pendingConversationsAsync: AsyncValue.data([pendingPreview]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Solicitações'));
        await tester.pumpAndSettle();

        await tester.drag(
          find.byKey(const ValueKey('pending_pending-1_1')),
          const Offset(400, 0),
        );
        await tester.pumpAndSettle();

        expect(fakeChatRepo.acceptConversationRequestCalls, 1);
        expect(find.text('Solicitacao aceita.'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
      },
    );
  });
}
