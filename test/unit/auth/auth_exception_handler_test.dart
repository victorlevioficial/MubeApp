import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/utils/auth_exception_handler.dart';

void main() {
  group('AuthExceptionHandler', () {
    test('returns original message when error is already a String', () {
      const message = 'Este e-mail ja esta cadastrado.';

      expect(AuthExceptionHandler.handleException(message), message);
    });

    test(
      'returns specific login message for invalid credential on email sign in',
      () {
        final error = FirebaseAuthException(code: 'invalid-credential');

        expect(
          AuthExceptionHandler.handleEmailPasswordSignInException(error),
          'E-mail ou senha incorretos. Confira os dados e tente novamente.',
        );
      },
    );

    test('keeps wrong password message specific on email sign in', () {
      final error = FirebaseAuthException(code: 'wrong-password');

      expect(
        AuthExceptionHandler.handleEmailPasswordSignInException(error),
        'Senha incorreta. Tente novamente.',
      );
    });
  });
}
