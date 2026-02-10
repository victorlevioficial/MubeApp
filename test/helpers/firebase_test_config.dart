// ignore_for_file: depend_on_referenced_packages

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// Initializes Firebase Core mocks for unit/integration tests.
///
/// Call this in `setUpAll()` to avoid
/// "No Firebase App '[DEFAULT]' has been created" errors.
///
/// Example:
/// ```dart
/// void main() {
///   setUpAll(() => setupFirebaseCoreMocks());
///   // ... tests
/// }
/// ```
Future<void> setupFirebaseCoreMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register the mock platform instance
  setupFirebaseCoreMockPlatform();
}

/// Sets up the mock Firebase Core platform using the official testing API.
void setupFirebaseCoreMockPlatform() {
  // Use the official mock from firebase_core_platform_interface
  final mockPlatform = MockFirebaseCorePlatform();
  FirebasePlatform.instance = mockPlatform;
}

/// A mock implementation of [FirebasePlatform] for testing.
class MockFirebaseCorePlatform extends FirebasePlatform {
  MockFirebaseCorePlatform() : super();

  bool get isAutomaticDataCollectionEnabled => false;

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _MockFirebaseAppPlatform(name, _defaultOptions);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _MockFirebaseAppPlatform(
      name ?? defaultFirebaseAppName,
      options ?? _defaultOptions,
    );
  }

  @override
  List<FirebaseAppPlatform> get apps => [
    _MockFirebaseAppPlatform(defaultFirebaseAppName, _defaultOptions),
  ];

  static const FirebaseOptions _defaultOptions = FirebaseOptions(
    apiKey: 'fake-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'fake-project-id',
    storageBucket: 'fake-project-id.appspot.com',
  );
}

class _MockFirebaseAppPlatform extends FirebaseAppPlatform {
  _MockFirebaseAppPlatform(String name, FirebaseOptions options)
    : super(name, options);

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> delete() async {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}
