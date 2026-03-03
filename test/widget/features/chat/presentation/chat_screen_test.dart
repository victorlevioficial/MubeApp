import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/chat/domain/message.dart';
import 'package:mube/src/features/chat/presentation/chat_screen.dart';

import '../../../../helpers/firebase_mocks.dart';
import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

class _ReadyChatRepository extends FakeChatRepository {
  final DocumentSnapshot<Map<String, dynamic>> _conversationDoc;

  _ReadyChatRepository({
    required String conversationId,
    required List<String> participants,
  }) : _conversationDoc = MockDocumentSnapshot<Map<String, dynamic>>(
         id: conversationId,
         data: {'participants': participants, 'readUntil': <String, dynamic>{}},
         exists: true,
       );

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
    return Stream.value(const []);
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late _ReadyChatRepository fakeChatRepo;
  late AppUser user;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    user = TestData.user(uid: 'user-1');
    fakeAuthRepo.appUser = user;
    fakeChatRepo = _ReadyChatRepository(
      conversationId: 'user-1_user-2',
      participants: const ['user-1', 'user-2'],
    );
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        chatRepositoryProvider.overrideWithValue(fakeChatRepo),
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
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    final field = tester.widget<EditableText>(find.byType(EditableText));

    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
  });
}
