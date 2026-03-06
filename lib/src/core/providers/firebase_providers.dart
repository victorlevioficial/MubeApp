import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();
const firebaseFunctionsRegion = 'southamerica-east1';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);
});

final firebaseAppCheckProvider = Provider<app_check.FirebaseAppCheck>((ref) {
  return app_check.FirebaseAppCheck.instance;
});

final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

final sharedPreferencesLoaderProvider = Provider<SharedPreferencesLoader>((
  ref,
) {
  return SharedPreferences.getInstance;
});
