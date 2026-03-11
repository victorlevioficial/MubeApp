import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/gigs/presentation/gig_error_message.dart';

void main() {
  test(
    'maps raw Firestore unauthenticated platform exception to session message',
    () {
      final message = resolveGigErrorMessage(
        PlatformException(
          code: 'firebase_firestore',
          message:
              'com.google.firebase.firestore.FirebaseFirestoreException: '
              'UNAUTHENTICATED (code: unauthenticated, message: '
              'The request does not have valid authentication credentials '
              'for the operation.)',
        ),
      );

      expect(message, 'Sua sessão expirou. Faça login novamente.');
    },
  );
}
