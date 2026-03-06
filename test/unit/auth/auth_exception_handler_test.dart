import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/utils/auth_exception_handler.dart';

void main() {
  group('AuthExceptionHandler', () {
    test('returns original message when error is already a String', () {
      const message = 'Este e-mail ja esta cadastrado.';

      expect(AuthExceptionHandler.handleException(message), message);
    });
  });
}
