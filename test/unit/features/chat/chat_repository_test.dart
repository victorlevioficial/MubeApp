import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';

@GenerateNiceMocks([MockSpec<AnalyticsService>()])
import 'chat_repository_test.mocks.dart';

class _SpyChatRepository extends ChatRepository {
  int getOrCreateConversationCalls = 0;

  _SpyChatRepository(super.firestore, {super.analytics});

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
    getOrCreateConversationCalls += 1;
    return super.getOrCreateConversation(
      myUid: myUid,
      otherUid: otherUid,
      otherUserName: otherUserName,
      otherUserPhoto: otherUserPhoto,
      myName: myName,
      myPhoto: myPhoto,
      type: type,
    );
  }
}

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

      test('should log chat_initiated only on first creation', () async {
        await repository.getOrCreateConversation(
          myUid: myUid,
          otherUid: otherUid,
          otherUserName: otherUserName,
          myName: myName,
        );
        await repository.getOrCreateConversation(
          myUid: myUid,
          otherUid: otherUid,
          otherUserName: otherUserName,
          myName: myName,
        );

        verify(
          mockAnalytics.logEvent(
            name: 'chat_initiated',
            parameters: anyNamed('parameters'),
          ),
        ).called(1);
      });
    });

    group('sendMessage', () {
      test(
        'should create conversation metadata on first message when conversation does not exist',
        () async {
          final spyRepository = _SpyChatRepository(
            fakeFirestore,
            analytics: mockAnalytics,
          );
          await fakeFirestore.collection('users').doc(myUid).set({
            'nome': myName,
          });
          await fakeFirestore.collection('users').doc(otherUid).set({
            'nome': otherUserName,
          });

          final result = await spyRepository.sendMessage(
            conversationId: conversationId,
            text: 'Primeira mensagem',
            myUid: myUid,
            otherUid: otherUid,
          );

          expect(result.isRight(), true);
          expect(spyRepository.getOrCreateConversationCalls, 1);

          final conversationDoc = await fakeFirestore
              .collection('conversations')
              .doc(conversationId)
              .get();
          expect(conversationDoc.exists, true);
          expect(
            conversationDoc.data()?['participants'],
            containsAll([myUid, otherUid]),
          );
          expect(
            conversationDoc.data()?['lastMessageText'],
            'Primeira mensagem',
          );

          final myPreview = await fakeFirestore
              .collection('users')
              .doc(myUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();
          expect(myPreview.exists, true);
          expect(myPreview.data()?['lastMessageText'], 'Primeira mensagem');

          final otherPreview = await fakeFirestore
              .collection('users')
              .doc(otherUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();
          expect(otherPreview.exists, true);
          expect(otherPreview.data()?['lastMessageText'], 'Primeira mensagem');

          verify(
            mockAnalytics.logEvent(
              name: 'chat_initiated',
              parameters: anyNamed('parameters'),
            ),
          ).called(1);
          verify(
            mockAnalytics.logEvent(
              name: 'message_sent',
              parameters: anyNamed('parameters'),
            ),
          ).called(1);
        },
      );

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

    group('getMessagesPage', () {
      test(
        'should return first page with hasMore when total > limit',
        () async {
          await fakeFirestore
              .collection('conversations')
              .doc(conversationId)
              .set({
                'participants': [myUid, otherUid],
              });

          for (var i = 0; i < 55; i++) {
            await fakeFirestore
                .collection('conversations')
                .doc(conversationId)
                .collection('messages')
                .doc('m_$i')
                .set({
                  'senderId': myUid,
                  'text': 'msg-$i',
                  'type': 'text',
                  'createdAt': Timestamp.fromMillisecondsSinceEpoch(i),
                });
          }

          final firstPage = await repository.getMessagesPage(
            conversationId: conversationId,
            limit: 50,
          );
          expect(firstPage.messages.length, 50);
          expect(firstPage.hasMore, true);
          expect(firstPage.lastVisibleDoc, isNotNull);
          expect(firstPage.messages.first.text, 'msg-54');
        },
      );

      test('should return hasMore false when total <= limit', () async {
        await fakeFirestore.collection('conversations').doc(conversationId).set(
          {
            'participants': [myUid, otherUid],
          },
        );

        for (var i = 0; i < 20; i++) {
          await fakeFirestore
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .doc('m_$i')
              .set({
                'senderId': myUid,
                'text': 'msg-$i',
                'type': 'text',
                'createdAt': Timestamp.fromMillisecondsSinceEpoch(i),
              });
        }

        final page = await repository.getMessagesPage(
          conversationId: conversationId,
          limit: 50,
        );
        expect(page.messages.length, 20);
        expect(page.hasMore, false);
        expect(page.lastVisibleDoc, isNotNull);
      });
    });

    group('deleteConversation', () {
      test('should delete only my preview and keep conversation', () async {
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
        expect(conversation.exists, true);

        final myPreview = await fakeFirestore
            .collection('users')
            .doc(myUid)
            .collection('conversationPreviews')
            .doc(conversationId)
            .get();
        expect(myPreview.exists, false);

        final otherPreview = await fakeFirestore
            .collection('users')
            .doc(otherUid)
            .collection('conversationPreviews')
            .doc(conversationId)
            .get();
        expect(otherPreview.exists, true);
      });
    });
  });
}
