import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';

@GenerateNiceMocks([MockSpec<AnalyticsService>()])
import 'chat_repository_test.mocks.dart';

void main() {
  late ChatRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAnalytics = MockAnalyticsService();
    repository = ChatRepository(fakeFirestore, analytics: mockAnalytics);
  });

  group('ChatRepository', () {
    const myUid = 'user1';
    const otherUid = 'user2';
    const otherUserName = 'John Doe';
    const myName = 'Jane Doe';
    const conversationId = 'user1_user2';

    group('getOrCreateConversation', () {
      test('should create new conversation when it does not exist', () async {
        final result = await repository.getOrCreateConversation(
          myUid: myUid,
          otherUid: otherUid,
          otherUserName: otherUserName,
          myName: myName,
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right'),
          (id) => expect(id, conversationId),
        );

        final conversationDoc = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .get();
        expect(conversationDoc.exists, true);
        expect(
          conversationDoc.data()?['participants'],
          containsAll([myUid, otherUid]),
        );

        final myPreview = await fakeFirestore
            .collection('users')
            .doc(myUid)
            .collection('conversationPreviews')
            .doc(conversationId)
            .get();
        expect(myPreview.exists, true);
        expect(myPreview.data()?['otherUserId'], otherUid);
      });
    });

    group('sendMessage', () {
      test('should send message successfully', () async {
        await repository.getOrCreateConversation(
          myUid: myUid,
          otherUid: otherUid,
          otherUserName: otherUserName,
          myName: myName,
        );

        final result = await repository.sendMessage(
          conversationId: conversationId,
          text: 'Hello!',
          myUid: myUid,
          otherUid: otherUid,
        );

        expect(result.isRight(), true);

        final messages = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .get();
        expect(messages.docs.length, 1);
        expect(messages.docs.first.data()['text'], 'Hello!');
      });
    });

    group('deleteConversation', () {
      test('should delete conversation and previews successfully', () async {
        await repository.getOrCreateConversation(
          myUid: myUid,
          otherUid: otherUid,
          otherUserName: otherUserName,
          myName: myName,
        );

        final result = await repository.deleteConversation(
          conversationId: conversationId,
          myUid: myUid,
          otherUid: otherUid,
        );

        expect(result.isRight(), true);

        final conversation = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .get();
        expect(conversation.exists, false);
      });
    });
  });
}
