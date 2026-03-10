import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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
      MockQuerySnapshot<Map<String, dynamic>>(data: _message?.toFirestore()),
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
    String conversationType = 'direct',
  }) async {
    sendCalls += 1;
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
    String conversationType = 'direct',
  }) async {
    sendCalls += 1;
    return const Right(unit);
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
      child: const MaterialApp(
        home: ChatScreen(
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

    expect(
      find.text('Nenhuma mensagem ainda\nEnvie a primeira!'),
      findsOneWidget,
    );

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
