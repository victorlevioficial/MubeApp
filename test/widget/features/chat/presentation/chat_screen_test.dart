import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/design_system/components/feedback/app_confirmation_dialog.dart';
import 'package:mube/src/design_system/foundations/tokens/app_typography.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/chat/data/chat_safety_repository.dart';
import 'package:mube/src/features/chat/domain/message.dart';
import 'package:mube/src/features/chat/presentation/chat_screen.dart';

import '../../../../helpers/firebase_mocks.dart';
import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

class _ReadyChatRepository extends FakeChatRepository {
  final DocumentSnapshot<Map<String, dynamic>> _conversationDoc;
  final Message? _message;
  int sendCalls = 0;
  String? lastReplyToMessageId;
  String? lastReplyToSenderId;
  String? lastReplyToText;
  String? lastReplyToType;

  _ReadyChatRepository({
    required String conversationId,
    required List<String> participants,
    Message? message,
  }) : _conversationDoc = MockDocumentSnapshot<Map<String, dynamic>>(
         id: conversationId,
         data: {'participants': participants, 'readUntil': <String, dynamic>{}},
         exists: true,
       ),
       _message = message;

  @override
  Future<DocumentSnapshot?> getConversationDoc(String conversationId) async {
    return _conversationDoc;
  }

  @override
  Stream<DocumentSnapshot> getConversationStream(String conversationId) {
    return Stream.value(_conversationDoc);
  }

  @override
  Stream<List<Message>> getMessages(String conversationId) {
    return Stream.value(_message == null ? const [] : [_message]);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesSnapshot(
    String conversationId, {
    int limit = 50,
  }) {
    return Stream.value(
      MockQuerySnapshot<Map<String, dynamic>>(
        data: _message?.toFirestore(),
        docId: _message?.id ?? 'test-doc-id',
      ),
    );
  }

  @override
  Future<MessagesPage> getMessagesPage({
    required String conversationId,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
    int limit = 50,
  }) async {
    return const MessagesPage(
      messages: [],
      lastVisibleDoc: null,
      hasMore: false,
    );
  }

  @override
  FutureResult<Unit> restoreConversationPreview({
    required String conversationId,
    required String myUid,
    required String otherUid,
    String? fallbackOtherUserName,
    String? fallbackOtherUserPhoto,
  }) async {
    return const Right(unit);
  }

  @override
  FutureResult<Unit> sendMessage({
    required String conversationId,
    required String text,
    required String myUid,
    required String otherUid,
    String? clientMessageId,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToText,
    String? replyToType,
    String conversationType = 'direct',
  }) async {
    sendCalls += 1;
    lastReplyToMessageId = replyToMessageId;
    lastReplyToSenderId = replyToSenderId;
    lastReplyToText = replyToText;
    lastReplyToType = replyToType;
    return const Right(unit);
  }
}

class _DraftChatRepository extends FakeChatRepository {
  final DocumentSnapshot<Map<String, dynamic>> _conversationDoc;
  int getOrCreateCalls = 0;
  int sendCalls = 0;

  _DraftChatRepository({required String conversationId})
    : _conversationDoc = MockDocumentSnapshot<Map<String, dynamic>>(
        id: conversationId,
        exists: false,
      );

  @override
  Future<DocumentSnapshot?> getConversationDoc(String conversationId) async {
    return null;
  }

  @override
  Stream<DocumentSnapshot> getConversationStream(String conversationId) {
    return Stream.value(_conversationDoc);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesSnapshot(
    String conversationId, {
    int limit = 50,
  }) {
    return Stream.value(MockQuerySnapshot<Map<String, dynamic>>(data: null));
  }

  @override
  FutureResult<String> getOrCreateConversation({
    required String myUid,
    required String otherUid,
    required String otherUserName,
    String? otherUserPhoto,
    required String myName,
    String? myPhoto,
    String type = 'direct',
  }) async {
    getOrCreateCalls += 1;
    return Right(getConversationId(myUid, otherUid));
  }

  @override
  FutureResult<Unit> sendMessage({
    required String conversationId,
    required String text,
    required String myUid,
    required String otherUid,
    String? clientMessageId,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToText,
    String? replyToType,
    String conversationType = 'direct',
  }) async {
    sendCalls += 1;
    return const Right(unit);
  }
}

class _DraftChatRepositoryWithoutMessagesSubscription
    extends _DraftChatRepository {
  int getMessagesSnapshotCalls = 0;

  _DraftChatRepositoryWithoutMessagesSubscription({
    required super.conversationId,
  });

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesSnapshot(
    String conversationId, {
    int limit = 50,
  }) {
    getMessagesSnapshotCalls += 1;
    return Stream.error(Exception('messages stream should stay idle'));
  }
}

class _DelayedRestoreChatRepository extends _ReadyChatRepository {
  final Completer<void> restoreCompleter;

  _DelayedRestoreChatRepository({
    required super.conversationId,
    required super.participants,
    required this.restoreCompleter,
  });

  @override
  FutureResult<Unit> restoreConversationPreview({
    required String conversationId,
    required String myUid,
    required String otherUid,
    String? fallbackOtherUserName,
    String? fallbackOtherUserPhoto,
  }) async {
    await restoreCompleter.future;
    return const Right(unit);
  }
}

class _PendingRecipientChatRepository extends FakeChatRepository {
  final DocumentSnapshot<Map<String, dynamic>> _conversationDoc;
  final Message? _message;
  int sendCalls = 0;
  int acceptCalls = 0;

  _PendingRecipientChatRepository({
    required String conversationId,
    required List<String> participants,
    Message? message,
  }) : _conversationDoc = MockDocumentSnapshot<Map<String, dynamic>>(
         id: conversationId,
         data: {
           'participants': participants,
           'readUntil': <String, dynamic>{},
           'requestStatus': 'pending',
           'requestSenderId': 'user-2',
           'requestRecipientId': 'user-1',
           'requestCycle': 1,
         },
         exists: true,
       ),
       _message = message;

  @override
  Future<DocumentSnapshot?> getConversationDoc(String conversationId) async {
    return _conversationDoc;
  }

  @override
  Stream<DocumentSnapshot> getConversationStream(String conversationId) {
    return Stream.value(_conversationDoc);
  }

  @override
  Stream<List<Message>> getMessages(String conversationId) {
    return Stream.value(_message == null ? const [] : [_message]);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesSnapshot(
    String conversationId, {
    int limit = 50,
  }) {
    return Stream.value(
      MockQuerySnapshot<Map<String, dynamic>>(
        data: _message?.toFirestore(),
        docId: _message?.id ?? 'test-doc-id',
      ),
    );
  }

  @override
  Future<MessagesPage> getMessagesPage({
    required String conversationId,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
    int limit = 50,
  }) async {
    return const MessagesPage(
      messages: [],
      lastVisibleDoc: null,
      hasMore: false,
    );
  }

  @override
  FutureResult<Unit> restoreConversationPreview({
    required String conversationId,
    required String myUid,
    required String otherUid,
    String? fallbackOtherUserName,
    String? fallbackOtherUserPhoto,
  }) async {
    return const Right(unit);
  }

  @override
  FutureResult<Unit> sendMessage({
    required String conversationId,
    required String text,
    required String myUid,
    required String otherUid,
    String? clientMessageId,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToText,
    String? replyToType,
    String conversationType = 'direct',
  }) async {
    sendCalls += 1;
    return const Right(unit);
  }

  @override
  FutureResult<Unit> acceptConversationRequest({
    required String conversationId,
    required String myUid,
    required String otherUid,
  }) async {
    acceptCalls += 1;
    return const Right(unit);
  }
}

class _SlowConversationAccessRepository extends FakeChatRepository {
  final Completer<DocumentSnapshot?> conversationDocCompleter;

  _SlowConversationAccessRepository({required this.conversationDocCompleter});

  @override
  Future<DocumentSnapshot?> getConversationDoc(String conversationId) {
    return conversationDocCompleter.future;
  }

  @override
  Stream<DocumentSnapshot> getConversationStream(String conversationId) {
    return Stream.value(
      MockDocumentSnapshot<Map<String, dynamic>>(
        id: conversationId,
        data: {
          'participants': const ['user-1', 'user-2'],
          'readUntil': <String, dynamic>{},
        },
        exists: true,
      ),
    );
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesSnapshot(
    String conversationId, {
    int limit = 50,
  }) {
    return Stream.value(MockQuerySnapshot<Map<String, dynamic>>(data: null));
  }

  @override
  FutureResult<Unit> restoreConversationPreview({
    required String conversationId,
    required String myUid,
    required String otherUid,
    String? fallbackOtherUserName,
    String? fallbackOtherUserPhoto,
  }) async {
    return const Right(unit);
  }
}

class _FakeChatSafetyRepository extends Fake implements ChatSafetyRepository {
  int logCalls = 0;
  String? lastText;

  @override
  Future<void> logPreSendWarning({
    required String conversationId,
    required String text,
    required List<String> clientPatterns,
    required List<String> clientChannels,
    required String severity,
  }) async {
    logCalls += 1;
    lastText = text;
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeChatRepository fakeChatRepo;
  late _FakeChatSafetyRepository fakeChatSafetyRepo;
  late AppUser user;
  late StreamController<AppUser?> profileController;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    user = TestData.user(uid: 'user-1');
    fakeAuthRepo.appUser = user;
    profileController = StreamController<AppUser?>();
    fakeChatSafetyRepo = _FakeChatSafetyRepository();
    fakeChatRepo = _ReadyChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
    );
  });

  tearDown(() async {
    await profileController.close();
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        currentUserProfileProvider.overrideWith(
          (ref) => profileController.stream,
        ),
        chatRepositoryProvider.overrideWithValue(fakeChatRepo),
        chatSafetyRepositoryProvider.overrideWithValue(fakeChatSafetyRepo),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: const ChatScreen(
          conversationId: 'user-1_user-2',
          extra: {'otherUserId': 'user-2', 'otherUserName': 'Other User'},
        ),
      ),
    );
  }

  testWidgets('uses multiline newline input for composing messages', (
    tester,
  ) async {
    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    final field = tester.widget<EditableText>(find.byType(EditableText));

    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
    expect(field.enableSuggestions, isTrue);
    expect(field.autocorrect, isTrue);
  });

  testWidgets('prepares conversation after delayed user profile load', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Other User'), findsOneWidget);

    profileController.add(user);
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma mensagem ainda\nEnvie a primeira!'),
      findsOneWidget,
    );
  });

  testWidgets('opens draft chat without creating conversation automatically', (
    tester,
  ) async {
    fakeChatRepo = _DraftChatRepository(conversationId: 'user-1_user-2');

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma mensagem ainda\nEnvie a primeira!'),
      findsOneWidget,
    );
    expect((fakeChatRepo as _DraftChatRepository).getOrCreateCalls, 0);
  });

  testWidgets(
    'does not subscribe to messages stream while draft conversation is not persisted',
    (tester) async {
      fakeAuthRepo = FakeAuthRepository(
        initialUser: FakeFirebaseUser(uid: 'user-1'),
      );
      fakeAuthRepo.appUser = user;
      final draftRepository = _DraftChatRepositoryWithoutMessagesSubscription(
        conversationId: 'user-1_user-2',
      );
      fakeChatRepo = draftRepository;

      profileController.add(user);
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhuma mensagem ainda\nEnvie a primeira!'),
        findsOneWidget,
      );
      expect(draftRepository.getMessagesSnapshotCalls, 0);
    },
  );

  testWidgets('does not block messages UI while restoring preview', (
    tester,
  ) async {
    final restoreCompleter = Completer<void>();
    fakeChatRepo = _DelayedRestoreChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
      restoreCompleter: restoreCompleter,
    );

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(EditableText), findsOneWidget);

    restoreCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows chat body immediately when preview already exists', (
    tester,
  ) async {
    final docCompleter = Completer<DocumentSnapshot?>();
    fakeChatRepo = _SlowConversationAccessRepository(
      conversationDocCompleter: docCompleter,
    );
    fakeChatRepo.setConversations([
      TestData.conversationPreview(
        id: 'user-1_user-2',
        otherUserId: 'user-2',
        otherUserName: 'Other User',
        lastMessageText: 'Oi',
      ),
    ]);

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump();

    expect(find.byType(EditableText), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    docCompleter.complete(
      MockDocumentSnapshot<Map<String, dynamic>>(
        id: 'user-1_user-2',
        data: {
          'participants': const ['user-1', 'user-2'],
          'readUntil': <String, dynamic>{},
        },
        exists: true,
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets(
    'keeps chat layout visible when auth exists before profile stream resolves',
    (tester) async {
      fakeAuthRepo = FakeAuthRepository(
        initialUser: FakeFirebaseUser(uid: 'user-1'),
      );
      fakeChatRepo = _SlowConversationAccessRepository(
        conversationDocCompleter: Completer<DocumentSnapshot?>(),
      );
      fakeChatRepo.setConversations([
        TestData.conversationPreview(
          id: 'user-1_user-2',
          otherUserId: 'user-2',
          otherUserName: 'Other User',
          lastMessageText: 'Oi',
        ),
      ]);

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump();

      expect(find.byType(EditableText), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('renders conversation messages with larger text size', (
    tester,
  ) async {
    final message = Message(
      id: 'message-1',
      senderId: 'user-2',
      text: 'Mensagem de teste',
      createdAt: Timestamp.now(),
    );
    fakeChatRepo = _ReadyChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
      message: message,
    );

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    final textWidget = tester.widget<Text>(find.text('Mensagem de teste'));

    expect(textWidget.style?.fontSize, AppTypography.bodyLarge.fontSize);
  });

  testWidgets('enters reply mode on swipe and sends reply payload', (
    tester,
  ) async {
    fakeAuthRepo = FakeAuthRepository(
      initialUser: FakeFirebaseUser(uid: 'user-1', emailVerified: true),
    );
    fakeAuthRepo.appUser = user;
    final replyRepository = _ReadyChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
      message: Message(
        id: 'message-1',
        senderId: 'user-2',
        text: 'Mensagem de teste',
        createdAt: Timestamp.now(),
      ),
    );
    fakeChatRepo = replyRepository;

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.drag(
      find.text('Mensagem de teste').first,
      const Offset(96, 0),
    );
    await tester.pump();

    expect(find.text('Respondendo a Other User'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'Resposta citada');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(replyRepository.sendCalls, 1);
    expect(replyRepository.lastReplyToMessageId, 'message-1');
    expect(replyRepository.lastReplyToSenderId, 'user-2');
    expect(replyRepository.lastReplyToText, 'Mensagem de teste');
    expect(replyRepository.lastReplyToType, 'text');
    expect(find.text('Respondendo a Other User'), findsNothing);
  });

  testWidgets('renders stored reply preview inside message bubble', (
    tester,
  ) async {
    fakeChatRepo = _ReadyChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
      message: Message(
        id: 'message-2',
        senderId: 'user-1',
        text: 'Resposta citada',
        createdAt: Timestamp.now(),
        replyToMessageId: 'message-1',
        replyToSenderId: 'user-2',
        replyToText: 'Mensagem original',
        replyToType: 'text',
      ),
    );

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Mensagem original'), findsOneWidget);
    expect(find.text('Resposta citada'), findsOneWidget);
  });

  testWidgets('enters reply mode on right swipe for my own messages', (
    tester,
  ) async {
    fakeAuthRepo = FakeAuthRepository(
      initialUser: FakeFirebaseUser(uid: 'user-1', emailVerified: true),
    );
    fakeAuthRepo.appUser = user;
    final replyRepository = _ReadyChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
      message: Message(
        id: 'message-own',
        senderId: 'user-1',
        text: 'Minha mensagem',
        createdAt: Timestamp.now(),
      ),
    );
    fakeChatRepo = replyRepository;

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.drag(find.text('Minha mensagem').first, const Offset(96, 0));
    await tester.pump();

    expect(find.text('Respondendo a Voce'), findsOneWidget);
  });

  testWidgets('enters reply mode on slow incremental swipe', (tester) async {
    final replyRepository = _ReadyChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
      message: Message(
        id: 'message-slow-swipe',
        senderId: 'user-2',
        text: 'Mensagem lenta',
        createdAt: Timestamp.now(),
      ),
    );
    fakeChatRepo = replyRepository;

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Mensagem lenta').first),
    );
    await gesture.moveBy(const Offset(16, 0));
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveBy(const Offset(16, 0));
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveBy(const Offset(16, 0));
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveBy(const Offset(16, 0));
    await tester.pump();

    expect(find.text('Respondendo a Other User'), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Respondendo a Other User'), findsOneWidget);
  });

  testWidgets('shows accept CTA and blocks reply for pending recipient', (
    tester,
  ) async {
    fakeChatRepo = _PendingRecipientChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
      message: Message(
        id: 'message-1',
        senderId: 'user-2',
        text: 'Oi, tudo bem?',
        createdAt: Timestamp.now(),
      ),
    );

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Aceitar solicitacao'), findsOneWidget);
    expect(find.text('Oi, tudo bem?'), findsOneWidget);
    expect(find.text('Aceite para responder'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'Resposta');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect((fakeChatRepo as _PendingRecipientChatRepository).sendCalls, 0);
  });

  testWidgets('accepts pending request from conversation screen', (
    tester,
  ) async {
    fakeChatRepo = _PendingRecipientChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
    );

    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceitar solicitacao'));
    await tester.pumpAndSettle();

    expect((fakeChatRepo as _PendingRecipientChatRepository).acceptCalls, 1);
    expect(
      find.text('Solicitacao aceita. Voce ja pode responder.'),
      findsOneWidget,
    );
    expect(find.text('Aceite para responder'), findsNothing);
    expect(find.text('Mensagem...'), findsOneWidget);
  });

  testWidgets('shows warning dialog and keeps draft for suspicious content', (
    tester,
  ) async {
    profileController.add(user);
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'me chama no whatsapp');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect((fakeChatRepo as _ReadyChatRepository).sendCalls, 0);
    expect(fakeChatSafetyRepo.logCalls, 1);
    expect(fakeChatSafetyRepo.lastText, 'me chama no whatsapp');
    expect(find.byType(AppConfirmationDialog), findsOneWidget);
    expect(
      find.text(
        'O chat do Mube não permite compartilhar contato ou levar a conversa para fora do app.',
      ),
      findsOneWidget,
    );
    expect(find.text('Editar mensagem'), findsOneWidget);
    expect(find.text('Entendi'), findsOneWidget);
    expect(find.text('me chama no whatsapp'), findsOneWidget);
  });
}
