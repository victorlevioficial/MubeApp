import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/utils/professional_profile_utils.dart';

void main() {
  group('professional_profile_utils profileStringList', () {
    test('normalizes list, scalar string and mixed legacy values safely', () {
      expect(profileStringList(['Guitarra', '  ', 42]), ['Guitarra', '42']);
      expect(profileStringList('Baixo'), ['Baixo']);
      expect(profileStringList('   '), isEmpty);
      expect(profileStringList(null), isEmpty);
    });
  });

  group('professional_profile_utils display labels', () {
    test('maps stored ids to user-facing labels', () {
      expect(professionalRoleDisplayLabel('tecnico_de_luz'), 'Técnico de Luz');
      expect(
        professionalRoleDisplayLabel('audiovisual_direcao_de_video'),
        'Direção de Vídeo',
      );
      expect(genreDisplayLabel('rock_classico'), 'Rock Clássico');
      expect(genreDisplayLabel('mpb'), 'MPB');
      expect(instrumentDisplayLabel('violao_7_cordas'), 'Violão 7 cordas');
      expect(
        studioServiceDisplayLabel('gravacao_de_bateria'),
        'Gravação de bateria',
      );
    });

    test('humanizes unknown stored ids as a safe fallback', () {
      expect(
        professionalRoleDisplayLabel('custom_stage_role'),
        'Custom Stage Role',
      );
    });
  });
}
