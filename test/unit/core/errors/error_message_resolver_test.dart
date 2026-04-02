import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/errors/error_message_resolver.dart';

void main() {
  group('resolveErrorMessage', () {
    test('maps raw not_found exceptions to a friendly message', () {
      final message = resolveErrorMessage(Exception('not_found'));

      expect(
        message,
        'Servico solicitado indisponivel no servidor. Atualize o aplicativo e tente novamente.',
      );
    });

    test('preserves regular exception messages', () {
      final message = resolveErrorMessage(Exception('Erro qualquer'));

      expect(message, 'Erro qualquer');
    });
  });
}
