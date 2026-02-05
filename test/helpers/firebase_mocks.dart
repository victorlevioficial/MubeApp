// ignore_for_file: subtype_of_sealed_class, must_be_immutable

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/mockito.dart';

/// Mock implementations for Firebase classes to be used in tests.
/// These mocks provide basic stub implementations that can be configured
/// as needed for specific test scenarios.

// Firebase Auth Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {
  final String? _uid;
  final String? _email;
  final String? _displayName;
  final String? _photoURL;

  MockUser({String? uid, String? email, String? displayName, String? photoURL})
    : _uid = uid,
      _email = email,
      _displayName = displayName,
      _photoURL = photoURL;

  @override
  String get uid => _uid ?? 'test-uid';

  @override
  String? get email => _email;

  @override
  String? get displayName => _displayName;

  @override
  String? get photoURL => _photoURL;

  @override
  bool get emailVerified => true;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'mock-id-token';
}

class MockUserCredential extends Mock implements UserCredential {
  final User? _user;

  MockUserCredential({User? user}) : _user = user;

  @override
  User? get user => _user;
}

// Firestore Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference<T> extends Mock
    implements CollectionReference<T> {
  final String _path;
  final T? _data;

  MockCollectionReference({String path = 'users', T? data})
    : _path = path,
      _data = data;

  @override
  String get path => _path;

  @override
  DocumentReference<T> doc([String? path]) {
    return MockDocumentReference<T>(id: path ?? 'test-doc-id', data: _data);
  }

  @override
  Query<T> orderBy(Object field, {bool descending = false}) {
    return MockQuery<T>(data: _data);
  }

  @override
  Query<T> limit(int limit) {
    return MockQuery<T>(data: _data);
  }

  @override
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return MockQuery<T>(data: _data);
  }
}

class MockDocumentReference<T> extends Mock implements DocumentReference<T> {
  final String _id;
  final T? _data;

  MockDocumentReference({required String id, T? data}) : _id = id, _data = data;

  @override
  String get id => _id;

  @override
  Future<void> set(T data, [SetOptions? options]) async {
    return;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    return;
  }

  @override
  Future<void> delete() async {
    return;
  }

  @override
  Future<DocumentSnapshot<T>> get([GetOptions? options]) async {
    return MockDocumentSnapshot<T>(id: _id, data: _data, exists: _data != null);
  }

  @override
  Stream<DocumentSnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.value(
      MockDocumentSnapshot<T>(id: _id, data: _data, exists: _data != null),
    );
  }
}

class MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T> {
  final String _id;
  final T? _data;
  final bool _exists;

  MockDocumentSnapshot({required String id, T? data, bool exists = true})
    : _id = id,
      _data = data,
      _exists = exists;

  @override
  String get id => _id;

  @override
  bool get exists => _exists;

  @override
  T? data() => _data;

  @override
  dynamic operator [](Object field) => (_data as Map<String, dynamic>?)?[field];

  @override
  DocumentReference<T> get reference =>
      MockDocumentReference<T>(id: _id, data: _data);
}

class MockQuery<T> extends Mock implements Query<T> {
  final T? _data;

  MockQuery({T? data}) : _data = data;

  @override
  Query<T> orderBy(Object field, {bool descending = false}) {
    return this;
  }

  @override
  Query<T> limit(int limit) {
    return this;
  }

  @override
  Query<T> startAfterDocument(DocumentSnapshot<Object?> documentSnapshot) {
    return this;
  }

  @override
  Future<QuerySnapshot<T>> get([GetOptions? options]) async {
    return MockQuerySnapshot<T>(data: _data);
  }
}

class MockQuerySnapshot<T> extends Mock implements QuerySnapshot<T> {
  final T? _data;

  MockQuerySnapshot({T? data}) : _data = data;

  @override
  List<QueryDocumentSnapshot<T>> get docs {
    if (_data == null) return [];
    return [MockQueryDocumentSnapshot<T>(id: 'test-doc-id', data: _data)];
  }

  @override
  List<DocumentChange<T>> get docChanges => [];

  @override
  SnapshotMetadata get metadata => MockSnapshotMetadata();

  @override
  int get size => _data != null ? 1 : 0;
}

class MockQueryDocumentSnapshot<T> extends Mock
    implements QueryDocumentSnapshot<T> {
  final String _id;
  final T? _data;

  MockQueryDocumentSnapshot({required String id, T? data})
    : _id = id,
      _data = data;

  @override
  String get id => _id;

  @override
  T data() => _data!;

  @override
  dynamic operator [](Object field) => (_data as Map<String, dynamic>?)?[field];

  @override
  bool get exists => _data != null;

  @override
  DocumentReference<T> get reference =>
      MockDocumentReference<T>(id: _id, data: _data);
}

class MockSnapshotMetadata extends Mock implements SnapshotMetadata {
  @override
  bool get isFromCache => false;

  @override
  bool get hasPendingWrites => false;
}

// Firebase Storage Mocks
class MockFirebaseStorage extends Mock implements FirebaseStorage {
  @override
  Reference ref([String? path]) {
    return MockReference(path: path ?? '');
  }
}

class MockReference extends Mock implements Reference {
  final String _path;

  MockReference({String path = ''}) : _path = path;

  @override
  String get fullPath => _path;

  @override
  String get name => _path.split('/').last;

  @override
  Reference child(String path) {
    return MockReference(path: '$_path/$path');
  }

  @override
  Future<String> getDownloadURL() async {
    return 'https://example.com/mock-image.png';
  }

  @override
  UploadTask putFile(dynamic file, [SettableMetadata? metadata]) {
    return MockUploadTask();
  }

  @override
  Future<void> delete() async {
    return;
  }
}

class MockUploadTask extends Mock implements UploadTask {
  @override
  Future<TaskSnapshot> whenComplete(FutureOr<void> Function() callback) async {
    await callback();
    return MockTaskSnapshot();
  }

  @override
  Stream<TaskSnapshot> get snapshotEvents =>
      Stream.value(MockTaskSnapshot(bytesTransferred: 100, totalBytes: 100));
}

class MockTaskSnapshot extends Mock implements TaskSnapshot {
  final int _bytesTransferred;
  final int _totalBytes;

  MockTaskSnapshot({int bytesTransferred = 0, int totalBytes = 0})
    : _bytesTransferred = bytesTransferred,
      _totalBytes = totalBytes;

  @override
  int get bytesTransferred => _bytesTransferred;

  @override
  int get totalBytes => _totalBytes;

  @override
  Reference get ref => MockReference();
}
