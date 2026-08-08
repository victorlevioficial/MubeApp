import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

const bool firebaseEmulatorsEnabled = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
);
const String firebaseEmulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

bool _firebaseEmulatorsConfigured = false;

Future<void> configureFirebaseEmulatorsIfEnabled() async {
  if (!firebaseEmulatorsEnabled || _firebaseEmulatorsConfigured) return;
  _firebaseEmulatorsConfigured = true;

  await FirebaseAuth.instance.useAuthEmulator(firebaseEmulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(firebaseEmulatorHost, 8080);
  await FirebaseStorage.instance.useStorageEmulator(firebaseEmulatorHost, 9199);
  FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  ).useFunctionsEmulator(firebaseEmulatorHost, 5001);
}
