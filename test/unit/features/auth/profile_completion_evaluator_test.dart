import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/profile_completion_evaluator.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';

void main() {
  AppUser buildProfessional({
    String cadastroStatus = 'concluido',
    Map<String, dynamic>? profissionalData,
    String? foto = 'https://example.com/profile.jpg',
  }) {
    return AppUser(
      uid: 'u1',
      email: 'user@example.com',
      cadastroStatus: cadastroStatus,
      tipoPerfil: AppUserType.professional,
      nome: 'Usuario Teste',
      foto: foto,
      location: const {'lat': -23.5, 'lng': -46.6},
      dadosProfissional:
          profissionalData ??
          const {
            'nomeArtistico': 'Nome Artistico',
            'celular': '(11) 99999-9999',
            'dataNascimento': '01/01/1990',
            'genero': 'Masculino',
            'gallery': [
              {'type': 'photo', 'url': 'https://example.com/p1.jpg'},
              {'type': 'video', 'url': 'https://example.com/v1.mp4'},
            ],
          },
    );
  }

  group('ProfileCompletionEvaluator', () {
    test('returns 100% for fully completed professional profile', () {
      final user = buildProfessional();

      final result = ProfileCompletionEvaluator.evaluate(user);

      expect(result.percent, 100);
      expect(result.isComplete, isTrue);
      expect(result.missingRequirements, isEmpty);
    });

    test('marks profile incomplete when gallery has no video', () {
      final user = buildProfessional(
        profissionalData: const {
          'nomeArtistico': 'Nome Artistico',
          'celular': '(11) 99999-9999',
          'dataNascimento': '01/01/1990',
          'genero': 'Masculino',
          'gallery': [
            {'type': 'photo', 'url': 'https://example.com/p1.jpg'},
          ],
        },
      );

      final result = ProfileCompletionEvaluator.evaluate(user);

      expect(result.percent, lessThan(100));
      expect(result.missingRequirements, contains('Galeria de videos'));
    });

    test('marks profile incomplete when gallery has no photo', () {
      final user = buildProfessional(
        profissionalData: const {
          'nomeArtistico': 'Nome Artistico',
          'celular': '(11) 99999-9999',
          'dataNascimento': '01/01/1990',
          'genero': 'Masculino',
          'gallery': [
            {'type': 'video', 'url': 'https://example.com/v1.mp4'},
          ],
        },
      );

      final result = ProfileCompletionEvaluator.evaluate(user);

      expect(result.percent, lessThan(100));
      expect(result.missingRequirements, contains('Galeria de fotos'));
    });

    test('marks profile incomplete when personal data is missing', () {
      final user = buildProfessional(
        profissionalData: const {
          'nomeArtistico': 'Nome Artistico',
          'gallery': [
            {'type': 'photo', 'url': 'https://example.com/p1.jpg'},
            {'type': 'video', 'url': 'https://example.com/v1.mp4'},
          ],
        },
      );

      final result = ProfileCompletionEvaluator.evaluate(user);

      expect(result.percent, lessThan(100));
      expect(result.missingRequirements, contains('Celular'));
      expect(result.missingRequirements, contains('Data de nascimento'));
      expect(result.missingRequirements, contains('Genero'));
    });

    test('marks profile incomplete when registration is not concluded', () {
      final user = buildProfessional(cadastroStatus: 'perfil_pendente');

      final result = ProfileCompletionEvaluator.evaluate(user);

      expect(result.percent, lessThan(100));
      expect(result.missingRequirements, contains('Cadastro concluido'));
    });

    test('supports legacy studio data saved in professional map', () {
      const user = AppUser(
        uid: 'studio-1',
        email: 'studio@example.com',
        cadastroStatus: 'concluido',
        tipoPerfil: AppUserType.studio,
        nome: 'Studio User',
        foto: 'https://example.com/studio.jpg',
        location: {'lat': -23.5, 'lng': -46.6},
        dadosProfissional: {
          'nomeArtistico': 'Studio Legacy',
          'celular': '(11) 98888-8888',
          'studioType': 'home_studio',
          'services': ['mixagem'],
          'gallery': [
            {'type': 'photo', 'url': 'https://example.com/p1.jpg'},
            {'type': 'video', 'url': 'https://example.com/v1.mp4'},
          ],
        },
      );

      final result = ProfileCompletionEvaluator.evaluate(user);

      expect(result.percent, 100);
      expect(result.isComplete, isTrue);
      expect(result.missingRequirements, isEmpty);
    });
  });
}
