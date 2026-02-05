import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/errors/failures.dart';

void main() {
  group('Failures', () {
    group('AuthFailure', () {
      test('should create with message', () {
        const failure = AuthFailure(message: 'Test error');
        expect(failure.message, 'Test error');
        expect(failure.toString(), 'Failure: Test error');
      });

      test('should create with debug message', () {
        const failure = AuthFailure(
          message: 'User error',
          debugMessage: 'Technical details',
        );
        expect(failure.toString(), 'Failure: User error (Technical details)');
      });

      test('factory userNotFound should have correct message', () {
        final failure = AuthFailure.userNotFound();
        expect(failure.message, 'Usuário não encontrado.');
        expect(failure.debugMessage, 'user-not-found');
      });

      test('factory wrongPassword should have correct message', () {
        final failure = AuthFailure.wrongPassword();
        expect(failure.message, 'Senha incorreta.');
        expect(failure.debugMessage, 'wrong-password');
      });

      test('factory emailAlreadyInUse should have correct message', () {
        final failure = AuthFailure.emailAlreadyInUse();
        expect(failure.message, 'Este e-mail já está cadastrado.');
        expect(failure.debugMessage, 'email-already-in-use');
      });
    });

    group('NetworkFailure', () {
      test('factory noConnection should have correct message', () {
        final failure = NetworkFailure.noConnection();
        expect(failure.message, 'Sem conexão com a internet.');
        expect(failure.debugMessage, 'no-connection');
      });

      test('factory timeout should have correct message', () {
        final failure = NetworkFailure.timeout();
        expect(failure.message, 'A conexão demorou muito. Tente novamente.');
        expect(failure.debugMessage, 'timeout');
      });
    });

    group('ServerFailure', () {
      test('should create with message', () {
        const failure = ServerFailure(message: 'Server error');
        expect(failure.message, 'Server error');
      });
    });

    group('ValidationFailure', () {
      test('should create with message', () {
        const failure = ValidationFailure(message: 'Invalid input');
        expect(failure.message, 'Invalid input');
      });
    });

    group('UnknownFailure', () {
      test('should create with default message', () {
        const failure = UnknownFailure();
        expect(failure.message, 'Algo deu errado. Tente novamente.');
      });

      test('should create with custom message', () {
        const failure = UnknownFailure(message: 'Custom error');
        expect(failure.message, 'Custom error');
      });
    });
  });
}
