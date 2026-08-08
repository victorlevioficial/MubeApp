import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/config/firebase_emulator_config.dart';

void main() {
  test(
    'Firebase emulators stay disabled without an explicit dart define',
    () async {
      expect(firebaseEmulatorsEnabled, isFalse);
      expect(firebaseEmulatorHost, '10.0.2.2');

      await expectLater(configureFirebaseEmulatorsIfEnabled(), completes);
    },
  );
}
