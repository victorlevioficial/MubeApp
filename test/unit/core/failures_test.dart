import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/errors/failures.dart';

void main() {
  group('Failure', () {
    test('AuthFailure has correct message', () {
      final failure = AuthFailure.userNotFound();
      expect(failure.message, 'Usuário não encontrado.');
      expect(failure.debugMessage, 'user-not-found');
    });

    test('AuthFailure.wrongPassword has correct message', () {
      final failure = AuthFailure.wrongPassword();
      expect(failure.message, 'Senha incorreta.');
    });

    test('AuthFailure.emailAlreadyInUse has correct message', () {
      final failure = AuthFailure.emailAlreadyInUse();
      expect(failure.message, 'Este e-mail já está cadastrado.');
    });

    test('AuthFailure.invalidEmail has correct message', () {
      final failure = AuthFailure.invalidEmail();
      expect(failure.message, 'E-mail inválido.');
    });

    test('AuthFailure.weakPassword has correct message', () {
      final failure = AuthFailure.weakPassword();
      expect(
        failure.message,
        'Senha muito fraca. Use pelo menos 6 caracteres.',
      );
    });

    test('AuthFailure.tooManyRequests has correct message', () {
      final failure = AuthFailure.tooManyRequests();
      expect(failure.message, 'Muitas tentativas. Tente novamente mais tarde.');
    });
  });

  group('NetworkFailure', () {
    test('noConnection has correct message', () {
      final failure = NetworkFailure.noConnection();
      expect(failure.message, 'Sem conexão com a internet.');
    });

    test('timeout has correct message', () {
      final failure = NetworkFailure.timeout();
      expect(failure.message, 'A conexão demorou muito. Tente novamente.');
    });

    test('serverError has correct message', () {
      final failure = NetworkFailure.serverError();
      expect(failure.message, 'Erro no servidor. Tente novamente mais tarde.');
    });
  });

  group('StorageFailure', () {
    test('fileTooLarge has correct message with size', () {
      final failure = StorageFailure.fileTooLarge(maxSizeMB: 10);
      expect(failure.message, 'Arquivo muito grande. Máximo: 10MB.');
    });

    test('fileTooLarge has generic message without size', () {
      final failure = StorageFailure.fileTooLarge();
      expect(failure.message, 'Arquivo muito grande.');
    });

    test('invalidFileType has correct message', () {
      final failure = StorageFailure.invalidFileType();
      expect(failure.message, 'Tipo de arquivo não suportado.');
    });

    test('uploadFailed has correct message', () {
      final failure = StorageFailure.uploadFailed();
      expect(failure.message, 'Erro ao enviar arquivo. Tente novamente.');
    });

    test('quotaExceeded has correct message', () {
      final failure = StorageFailure.quotaExceeded();
      expect(failure.message, 'Limite de armazenamento atingido.');
    });
  });

  group('ValidationFailure', () {
    test('requiredField has correct message', () {
      final failure = ValidationFailure.requiredField('Nome');
      expect(failure.message, 'Nome é obrigatório.');
    });

    test('invalidFormat has correct message', () {
      final failure = ValidationFailure.invalidFormat('e-mail');
      expect(failure.message, 'Formato de e-mail inválido.');
    });
  });

  group('PermissionFailure', () {
    test('camera has correct message', () {
      final failure = PermissionFailure.camera();
      expect(
        failure.message,
        'Permissão de câmera negada. Habilite nas configurações.',
      );
    });

    test('gallery has correct message', () {
      final failure = PermissionFailure.gallery();
      expect(
        failure.message,
        'Permissão de galeria negada. Habilite nas configurações.',
      );
    });

    test('location has correct message', () {
      final failure = PermissionFailure.location();
      expect(
        failure.message,
        'Permissão de localização negada. Habilite nas configurações.',
      );
    });
  });

  group('UnknownFailure', () {
    test('has default message', () {
      const failure = UnknownFailure();
      expect(failure.message, 'Algo deu errado. Tente novamente.');
    });

    test('can have custom debugMessage', () {
      const failure = UnknownFailure(debugMessage: 'Custom debug');
      expect(failure.debugMessage, 'Custom debug');
    });

    test('can store original error', () {
      final originalError = Exception('Original');
      final failure = UnknownFailure(originalError: originalError);
      expect(failure.originalError, originalError);
    });
  });

  group('Failure.toString', () {
    test('includes message', () {
      const failure = UnknownFailure(message: 'Test message');
      expect(failure.toString(), contains('Test message'));
    });

    test('includes debugMessage when present', () {
      const failure = UnknownFailure(
        message: 'Test',
        debugMessage: 'debug-info',
      );
      expect(failure.toString(), contains('debug-info'));
    });
  });
}
