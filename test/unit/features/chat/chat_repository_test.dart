// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
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

class _RefreshingAuthRepository extends Fake implements AuthRepository {
  int refreshCalls = 0;

  @override
  FutureResult<Unit> refreshSecurityContext() async {
    refreshCalls++;
    return const Right(unit);
  }
}

class _RetryingFirebaseFirestore extends Fake implements FirebaseFirestore {
  _RetryingFirebaseFirestore({
    required Map<String, Map<String, dynamic>> documents,
  }) : _documents = documents;

  final Map<String, Map<String, dynamic>> _documents;
  int batchCreationCount = 0;
  int commitAttemptCount = 0;
  int _autoIdCounter = 0;

  @override
  WriteBatch batch() {
    batchCreationCount++;
    return _RetryingWriteBatch(this);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _RetryingCollectionReference(this, path);
  }

  String nextAutoId() => 'auto_${_autoIdCounter++}';

  Map<String, dynamic>? readDocument(String path) => _documents[path];
}

class _RetryingCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _RetryingCollectionReference(this._firestore, this._path);

  final _RetryingFirebaseFirestore _firestore;
  final String _path;

  @override
  String get path => _path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? _firestore.nextAutoId();
    return _RetryingDocumentReference(_firestore, '$_path/$docId');
  }
}

class _RetryingDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _RetryingDocumentReference(this._firestore, this._path);

  final _RetryingFirebaseFirestore _firestore;
  final String _path;

  @override
  String get id => _path.split('/').last;

  @override
  String get path => _path;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _RetryingCollectionReference(_firestore, '$_path/$collectionPath');
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    return _RetryingDocumentSnapshot(this, _firestore.readDocument(_path));
  }
}

class _RetryingDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _RetryingDocumentSnapshot(this._reference, this._data);

  final _RetryingDocumentReference _reference;
  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  String get id => _reference.id;

  @override
  DocumentReference<Map<String, dynamic>> get reference => _reference;

  @override
  Map<String, dynamic>? data() => _data;
}

class _RetryingWriteBatch extends Fake implements WriteBatch {
  _RetryingWriteBatch(this._firestore);

  final _RetryingFirebaseFirestore _firestore;
  bool _committed = false;

  StateError _committedError() => StateError(
    'This batch has already been committed and can no longer be changed.',
  );

  @override
  void delete(DocumentReference<Object?> document) {
    if (_committed) throw _committedError();
  }

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    if (_committed) throw _committedError();
  }

  @override
  void update(DocumentReference<Object?> document, Map<Object, Object?> data) {
    if (_committed) throw _committedError();
  }

  @override
  Future<void> commit() async {
    if (_committed) throw _committedError();
    _committed = true;
    _firestore.commitAttemptCount++;

    if (_firestore.commitAttemptCount == 1) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message:
            'The caller does not have permission to execute the specified operation.',
      );
    }
  }
}

class _RulesAwareFirebaseFirestore extends Fake implements FirebaseFirestore {
  _RulesAwareFirebaseFirestore({
    required Map<String, Map<String, dynamic>> documents,
  }) : _documents = Map<String, Map<String, dynamic>>.from(documents);

  final Map<String, Map<String, dynamic>> _documents;
  int _autoIdCounter = 0;
  int transactionCount = 0;

  @override
  WriteBatch batch() => _RulesAwareWriteBatch(this);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _RulesAwareCollectionReference(this, path);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    transactionCount++;
    final transaction = _RulesAwareTransaction(this);
    final result = await transactionHandler(transaction);
    transaction.apply();
    return result;
  }

  String nextAutoId() => 'auto_${_autoIdCounter++}';

  Map<String, dynamic>? readDocument(String path) {
    final data = _documents[path];
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  void writeDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    if (!merge || !_documents.containsKey(path)) {
      _documents[path] = Map<String, dynamic>.from(data);
      return;
    }

    final current = _documents[path]!;
    final merged = <String, dynamic>{...current};
    data.forEach((key, value) {
      if (value is FieldValue) {
        merged[key] = current[key];
      } else {
        merged[key] = value;
      }
    });
    _documents[path] = merged;
  }
}

class _RulesAwareCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _RulesAwareCollectionReference(this._firestore, this._path);

  final _RulesAwareFirebaseFirestore _firestore;
  final String _path;

  @override
  String get path => _path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? _firestore.nextAutoId();
    return _RulesAwareDocumentReference(_firestore, '$_path/$docId');
  }
}

class _RulesAwareDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _RulesAwareDocumentReference(this._firestore, this._path);

  final _RulesAwareFirebaseFirestore _firestore;
  final String _path;

  @override
  String get id => _path.split('/').last;

  @override
  String get path => _path;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _RulesAwareCollectionReference(_firestore, '$_path/$collectionPath');
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    return _RulesAwareDocumentSnapshot(this, _firestore.readDocument(_path));
  }
}

class _RulesAwareDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _RulesAwareDocumentSnapshot(this._reference, this._data);

  final _RulesAwareDocumentReference _reference;
  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  String get id => _reference.id;

  @override
  DocumentReference<Map<String, dynamic>> get reference => _reference;

  @override
  Map<String, dynamic>? data() => _data;
}

class _RulesAwareTransaction extends Fake implements Transaction {
  _RulesAwareTransaction(this._firestore);

  final _RulesAwareFirebaseFirestore _firestore;
  final List<({String path, Map<String, dynamic> data, bool merge})> _writes =
      [];

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    final path = (documentReference as dynamic).path as String;
    return _RulesAwareDocumentSnapshot(
          documentReference as _RulesAwareDocumentReference,
          _firestore.readDocument(path),
        )
        as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> document,
    T data, [
    SetOptions? options,
  ]) {
    _writes.add((
      path: (document as dynamic).path as String,
      data: Map<String, dynamic>.from(data as Map),
      merge: options?.merge ?? false,
    ));
    return this;
  }

  void apply() {
    for (final write in _writes) {
      _firestore.writeDocument(write.path, write.data, merge: write.merge);
    }
  }
}

class _RulesAwareWriteBatch extends Fake implements WriteBatch {
  _RulesAwareWriteBatch(this._firestore);

  final _RulesAwareFirebaseFirestore _firestore;
  final List<({String path, Map<String, dynamic> data, bool merge})> _writes =
      [];

  @override
  void delete(DocumentReference<Object?> document) {}

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    _writes.add((
      path: (document as dynamic).path as String,
      data: Map<String, dynamic>.from(data as Map),
      merge: options?.merge ?? false,
    ));
  }

  @override
  void update(DocumentReference<Object?> document, Map<Object, Object?> data) {
    _writes.add((
      path: (document as dynamic).path as String,
      data: data.map((key, value) => MapEntry(key.toString(), value)),
      merge: true,
    ));
  }

  @override
  Future<void> commit() async {
    for (final write in _writes) {
      const messageMarker = '/messages/';
      final markerIndex = write.path.indexOf(messageMarker);
      if (markerIndex == -1) continue;

      final conversationPath = write.path.substring(0, markerIndex);
      final conversationExistsBeforeBatch =
          _firestore.readDocument(conversationPath) != null;
      final sameBatchCreatesConversation = _writes.any(
        (candidate) => candidate.path == conversationPath,
      );

      if (!conversationExistsBeforeBatch && sameBatchCreatesConversation) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message:
              'Simulated Rules: message create requires an existing conversation document.',
        );
      }
    }

    for (final write in _writes) {
      _firestore.writeDocument(write.path, write.data, merge: write.merge);
    }
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
        expect(conversationDoc.data()?['requestStatus'], 'accepted');
        expect(conversationDoc.data()?['requestCycle'], 0);

        final myPreview = await fakeFirestore
            .collection('users')
            .doc(myUid)
            .collection('conversationPreviews')
            .doc(conversationId)
            .get();
        expect(myPreview.exists, true);
        expect(myPreview.data()?['otherUserId'], otherUid);
        expect(myPreview.data()?['isPending'], false);
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
          expect(spyRepository.getOrCreateConversationCalls, 0);

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
          expect(conversationDoc.data()?['requestStatus'], 'accepted');

          final myPreview = await fakeFirestore
              .collection('users')
              .doc(myUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();
          expect(myPreview.exists, true);
          expect(myPreview.data()?['lastMessageText'], 'Primeira mensagem');
          expect(myPreview.data()?['isPending'], false);

          final otherPreview = await fakeFirestore
              .collection('users')
              .doc(otherUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();
          expect(otherPreview.exists, true);
          expect(otherPreview.data()?['lastMessageText'], 'Primeira mensagem');
          expect(otherPreview.data()?['isPending'], false);

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

      test(
        'should bootstrap the conversation before writing the first message under restrictive rules',
        () async {
          const firstMessageText = 'Primeira mensagem';
          final rulesAwareFirestore = _RulesAwareFirebaseFirestore(
            documents: {
              'users/$myUid': {'nome': myName},
              'users/$otherUid': {'nome': otherUserName},
            },
          );
          final rulesAwareRepository = ChatRepository(
            rulesAwareFirestore,
            analytics: mockAnalytics,
          );

          final result = await rulesAwareRepository.sendMessage(
            conversationId: conversationId,
            text: firstMessageText,
            myUid: myUid,
            otherUid: otherUid,
          );

          expect(result.isRight(), true);
          expect(rulesAwareFirestore.transactionCount, 1);
          expect(
            rulesAwareFirestore.readDocument('conversations/$conversationId'),
            isNotNull,
          );
          expect(
            rulesAwareFirestore.readDocument(
              'conversations/$conversationId/messages/auto_0',
            ),
            isNotNull,
          );
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

      test('should persist reply metadata when sending a reply', () async {
        await repository.getOrCreateConversation(
          myUid: myUid,
          otherUid: otherUid,
          otherUserName: otherUserName,
          myName: myName,
        );

        final result = await repository.sendMessage(
          conversationId: conversationId,
          text: 'Resposta',
          myUid: myUid,
          otherUid: otherUid,
          replyToMessageId: 'message-0',
          replyToSenderId: otherUid,
          replyToText: 'Mensagem original',
          replyToType: 'text',
        );

        expect(result.isRight(), true);

        final messages = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .get();
        expect(messages.docs.length, 1);
        expect(messages.docs.first.data()['replyToMessageId'], 'message-0');
        expect(messages.docs.first.data()['replyToSenderId'], otherUid);
        expect(messages.docs.first.data()['replyToText'], 'Mensagem original');
        expect(messages.docs.first.data()['replyToType'], 'text');
      });

      test(
        'should recreate the write batch after refreshing security context',
        () async {
          final retryingFirestore = _RetryingFirebaseFirestore(
            documents: {
              'conversations/$conversationId': {
                'participants': [myUid, otherUid],
                'type': 'direct',
                'requestStatus': 'accepted',
                'requestCycle': 0,
              },
              'users/$myUid': {'nome': myName},
              'users/$otherUid': {'nome': otherUserName},
            },
          );
          final authRepository = _RefreshingAuthRepository();
          final retryingRepository = ChatRepository(
            retryingFirestore,
            analytics: mockAnalytics,
            authRepository: authRepository,
          );

          final result = await retryingRepository.sendMessage(
            conversationId: conversationId,
            text: 'Retry message',
            myUid: myUid,
            otherUid: otherUid,
          );

          expect(result.isRight(), true);
          expect(authRepository.refreshCalls, 1);
          expect(retryingFirestore.batchCreationCount, 2);
          expect(retryingFirestore.commitAttemptCount, 2);
          verify(
            mockAnalytics.logEvent(
              name: 'message_sent',
              parameters: anyNamed('parameters'),
            ),
          ).called(1);
        },
      );

      test(
        'should send first message as pending request when recipient chat is private',
        () async {
          await fakeFirestore.collection('users').doc(myUid).set({
            'nome': myName,
          });
          await fakeFirestore.collection('users').doc(otherUid).set({
            'nome': otherUserName,
            'privacy_settings': {'chat_open': false},
          });

          final result = await repository.sendMessage(
            conversationId: conversationId,
            text: 'Quero falar com voce',
            myUid: myUid,
            otherUid: otherUid,
          );

          expect(result.isRight(), true);

          final conversationDoc = await fakeFirestore
              .collection('conversations')
              .doc(conversationId)
              .get();
          expect(conversationDoc.data()?['requestStatus'], 'pending');
          expect(conversationDoc.data()?['requestSenderId'], myUid);
          expect(conversationDoc.data()?['requestRecipientId'], otherUid);
          expect(conversationDoc.data()?['requestCycle'], 1);

          final myPreview = await fakeFirestore
              .collection('users')
              .doc(myUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();
          final otherPreview = await fakeFirestore
              .collection('users')
              .doc(otherUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();

          expect(myPreview.data()?['isPending'], false);
          expect(myPreview.data()?['requestCycle'], 1);
          expect(otherPreview.data()?['isPending'], true);
          expect(otherPreview.data()?['requestCycle'], 1);
        },
      );

      test(
        'should block recipient reply while request is still pending',
        () async {
          await fakeFirestore.collection('users').doc(myUid).set({
            'nome': myName,
          });
          await fakeFirestore.collection('users').doc(otherUid).set({
            'nome': otherUserName,
            'privacy_settings': {'chat_open': false},
          });

          await repository.sendMessage(
            conversationId: conversationId,
            text: 'Primeiro contato',
            myUid: myUid,
            otherUid: otherUid,
          );

          final result = await repository.sendMessage(
            conversationId: conversationId,
            text: 'Resposta antes de aceitar',
            myUid: otherUid,
            otherUid: myUid,
          );

          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(
              failure.message,
              contains('Aceite a solicitação antes de responder'),
            ),
            (_) => fail('Expected Left'),
          );
        },
      );
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

    group('request lifecycle', () {
      test(
        'should accept pending request and clear pending previews',
        () async {
          await fakeFirestore.collection('users').doc(myUid).set({
            'nome': myName,
          });
          await fakeFirestore.collection('users').doc(otherUid).set({
            'nome': otherUserName,
            'privacy_settings': {'chat_open': false},
          });
          await repository.sendMessage(
            conversationId: conversationId,
            text: 'Solicitação',
            myUid: myUid,
            otherUid: otherUid,
          );

          final result = await repository.acceptConversationRequest(
            conversationId: conversationId,
            myUid: otherUid,
            otherUid: myUid,
          );

          expect(result.isRight(), true);

          final conversationDoc = await fakeFirestore
              .collection('conversations')
              .doc(conversationId)
              .get();
          expect(conversationDoc.data()?['requestStatus'], 'accepted');

          final myPreview = await fakeFirestore
              .collection('users')
              .doc(myUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();
          final otherPreview = await fakeFirestore
              .collection('users')
              .doc(otherUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();

          expect(myPreview.data()?['isPending'], false);
          expect(otherPreview.data()?['isPending'], false);
        },
      );

      test(
        'should reject pending request and remove recipient preview',
        () async {
          await fakeFirestore.collection('users').doc(myUid).set({
            'nome': myName,
          });
          await fakeFirestore.collection('users').doc(otherUid).set({
            'nome': otherUserName,
            'privacy_settings': {'chat_open': false},
          });
          await repository.sendMessage(
            conversationId: conversationId,
            text: 'Solicitação',
            myUid: myUid,
            otherUid: otherUid,
          );

          final result = await repository.rejectConversationRequest(
            conversationId: conversationId,
            myUid: otherUid,
            otherUid: myUid,
          );

          expect(result.isRight(), true);

          final conversationDoc = await fakeFirestore
              .collection('conversations')
              .doc(conversationId)
              .get();
          expect(conversationDoc.data()?['requestStatus'], 'rejected');

          final senderPreview = await fakeFirestore
              .collection('users')
              .doc(myUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();
          final recipientPreview = await fakeFirestore
              .collection('users')
              .doc(otherUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();

          expect(senderPreview.exists, true);
          expect(senderPreview.data()?['isPending'], false);
          expect(recipientPreview.exists, false);
        },
      );

      test(
        'should reopen same thread with a new pending cycle after rejection',
        () async {
          await fakeFirestore.collection('users').doc(myUid).set({
            'nome': myName,
          });
          await fakeFirestore.collection('users').doc(otherUid).set({
            'nome': otherUserName,
            'privacy_settings': {'chat_open': false},
          });
          await repository.sendMessage(
            conversationId: conversationId,
            text: 'Solicitação 1',
            myUid: myUid,
            otherUid: otherUid,
          );
          await repository.rejectConversationRequest(
            conversationId: conversationId,
            myUid: otherUid,
            otherUid: myUid,
          );

          final result = await repository.sendMessage(
            conversationId: conversationId,
            text: 'Solicitação 2',
            myUid: myUid,
            otherUid: otherUid,
          );

          expect(result.isRight(), true);

          final conversationDoc = await fakeFirestore
              .collection('conversations')
              .doc(conversationId)
              .get();
          expect(conversationDoc.data()?['requestStatus'], 'pending');
          expect(conversationDoc.data()?['requestCycle'], 2);

          final recipientPreview = await fakeFirestore
              .collection('users')
              .doc(otherUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();

          expect(recipientPreview.exists, true);
          expect(recipientPreview.data()?['isPending'], true);
          expect(recipientPreview.data()?['requestCycle'], 2);
        },
      );

      test(
        'should promote pending conversation when recipient chat becomes public',
        () async {
          await fakeFirestore.collection('users').doc(myUid).set({
            'nome': myName,
          });
          await fakeFirestore.collection('users').doc(otherUid).set({
            'nome': otherUserName,
            'privacy_settings': {'chat_open': false},
          });
          await repository.sendMessage(
            conversationId: conversationId,
            text: 'Solicitação',
            myUid: myUid,
            otherUid: otherUid,
          );

          await fakeFirestore.collection('users').doc(otherUid).set({
            'nome': otherUserName,
            'privacy_settings': {'chat_open': true},
          });

          final result = await repository.reevaluateConversationAccess(
            conversationId: conversationId,
            trigger: 'privacy_settings_changed',
          );

          expect(result.isRight(), true);

          final conversationDoc = await fakeFirestore
              .collection('conversations')
              .doc(conversationId)
              .get();
          expect(conversationDoc.data()?['requestStatus'], 'accepted');

          final recipientPreview = await fakeFirestore
              .collection('users')
              .doc(otherUid)
              .collection('conversationPreviews')
              .doc(conversationId)
              .get();
          expect(recipientPreview.data()?['isPending'], false);
        },
      );
    });
  });
}
