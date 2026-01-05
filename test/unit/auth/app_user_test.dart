import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';

void main() {
  group('AppUser', () {
    group('cadastroStatus helpers', () {
      test('isTipoPendente returns true when status is tipo_pendente', () {
        const user = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          cadastroStatus: 'tipo_pendente',
        );

        expect(user.isTipoPendente, true);
        expect(user.isPerfilPendente, false);
        expect(user.isCadastroConcluido, false);
      });

      test('isPerfilPendente returns true when status is perfil_pendente', () {
        const user = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          cadastroStatus: 'perfil_pendente',
        );

        expect(user.isTipoPendente, false);
        expect(user.isPerfilPendente, true);
        expect(user.isCadastroConcluido, false);
      });

      test('isCadastroConcluido returns true when status is concluido', () {
        const user = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          cadastroStatus: 'concluido',
        );

        expect(user.isTipoPendente, false);
        expect(user.isPerfilPendente, false);
        expect(user.isCadastroConcluido, true);
      });
    });

    group('tipoPerfil', () {
      test('can be set to professional', () {
        const user = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          tipoPerfil: AppUserType.professional,
        );

        expect(user.tipoPerfil, AppUserType.professional);
      });

      test('can be set to band', () {
        const user = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          tipoPerfil: AppUserType.band,
        );

        expect(user.tipoPerfil, AppUserType.band);
      });

      test('can be set to studio', () {
        const user = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          tipoPerfil: AppUserType.studio,
        );

        expect(user.tipoPerfil, AppUserType.studio);
      });

      test('can be set to contractor', () {
        const user = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          tipoPerfil: AppUserType.contractor,
        );

        expect(user.tipoPerfil, AppUserType.contractor);
      });
    });

    group('default values', () {
      test('cadastroStatus defaults to tipo_pendente', () {
        const user = AppUser(uid: 'test-uid', email: 'test@example.com');

        expect(user.cadastroStatus, 'tipo_pendente');
      });

      test('status defaults to ativo', () {
        const user = AppUser(uid: 'test-uid', email: 'test@example.com');

        expect(user.status, 'ativo');
      });

      test('optional fields are null by default', () {
        const user = AppUser(uid: 'test-uid', email: 'test@example.com');

        expect(user.nome, isNull);
        expect(user.foto, isNull);
        expect(user.bio, isNull);
        expect(user.location, isNull);
        expect(user.tipoPerfil, isNull);
        expect(user.dadosProfissional, isNull);
        expect(user.dadosBanda, isNull);
        expect(user.dadosEstudio, isNull);
        expect(user.dadosContratante, isNull);
      });
    });

    group('copyWith', () {
      test('creates a copy with updated fields', () {
        const original = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          cadastroStatus: 'tipo_pendente',
        );

        final updated = original.copyWith(
          nome: 'Test User',
          cadastroStatus: 'concluido',
        );

        expect(updated.uid, 'test-uid');
        expect(updated.email, 'test@example.com');
        expect(updated.nome, 'Test User');
        expect(updated.cadastroStatus, 'concluido');
      });
    });
  });
}
