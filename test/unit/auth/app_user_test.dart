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
        expect(user.musicLinks, isEmpty);
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

    group('profileBio', () {
      test('uses nested band bio when top-level bio is empty', () {
        const user = AppUser(
          uid: 'band-uid',
          email: 'band@example.com',
          tipoPerfil: AppUserType.band,
          dadosBanda: {'nomeBanda': 'Banda Teste', 'bio': 'Bio da banda'},
        );

        expect(user.profileBio, 'Bio da banda');
      });

      test('uses legacy studio bio saved in professional data', () {
        const user = AppUser(
          uid: 'studio-uid',
          email: 'studio@example.com',
          tipoPerfil: AppUserType.studio,
          dadosProfissional: {
            'nomeArtistico': 'Studio Legacy',
            'bio': 'Bio legacy do estudio',
          },
        );

        expect(user.profileBio, 'Bio legacy do estudio');
      });
    });

    group('musicLinks serialization', () {
      test('serializes musicLinks using music_links key', () {
        const user = AppUser(
          uid: 'artist-uid',
          email: 'artist@example.com',
          musicLinks: {'spotify': 'https://open.spotify.com/artist/test'},
        );

        final json = user.toJson();

        expect(json['music_links'], {
          'spotify': 'https://open.spotify.com/artist/test',
        });
      });

      test('deserializes music_links into musicLinks', () {
        final user = AppUser.fromJson({
          'uid': 'artist-uid',
          'email': 'artist@example.com',
          'music_links': {'deezer': 'https://www.deezer.com/artist/test'},
        });

        expect(user.musicLinks, {
          'deezer': 'https://www.deezer.com/artist/test',
        });
      });
    });

    group('profile accessors', () {
      test('profilePhone reads celular from dadosProfissional', () {
        const user = AppUser(
          uid: 'pro-uid',
          email: 'pro@example.com',
          tipoPerfil: AppUserType.professional,
          dadosProfissional: {
            'nomeArtistico': 'DJ Test',
            'celular': '11999999999',
            'dataNascimento': '01/01/1990',
            'genero': 'Masculino',
            'instagram': '@djtest',
          },
        );

        expect(user.profilePhone, '11999999999');
        expect(user.profileBirthDate, '01/01/1990');
        expect(user.profileGender, 'Masculino');
        expect(user.profileInstagram, '@djtest');
      });

      test('profilePhone reads celular from dadosContratante', () {
        const user = AppUser(
          uid: 'contractor-uid',
          email: 'contractor@example.com',
          tipoPerfil: AppUserType.contractor,
          dadosContratante: {
            'nomeExibicao': 'Casa Show',
            'celular': '21988887777',
            'instagram': '@casashow',
          },
        );

        expect(user.profilePhone, '21988887777');
        expect(user.profileInstagram, '@casashow');
      });

      test('profile accessors return empty string when field is missing', () {
        const user = AppUser(
          uid: 'pro-uid',
          email: 'pro@example.com',
          tipoPerfil: AppUserType.professional,
          dadosProfissional: {'nomeArtistico': 'DJ Test'},
        );

        expect(user.profilePhone, '');
        expect(user.profileBirthDate, '');
        expect(user.profileGender, '');
        expect(user.profileInstagram, '');
      });

      test('profileInstagram reads from dadosBanda for band profile', () {
        const user = AppUser(
          uid: 'band-uid',
          email: 'band@example.com',
          tipoPerfil: AppUserType.band,
          dadosBanda: {'nomeBanda': 'Banda Teste', 'instagram': '@bandateste'},
        );

        expect(user.profileInstagram, '@bandateste');
      });

      test('profile accessors return empty for unknown tipoPerfil', () {
        const user = AppUser(uid: 'uid', email: 'e@x.com');

        expect(user.profilePhone, '');
        expect(user.profileBirthDate, '');
        expect(user.profileGender, '');
        expect(user.profileInstagram, '');
      });

      test('professional list accessors normalize Iterable values', () {
        const user = AppUser(
          uid: 'pro-uid',
          email: 'pro@example.com',
          tipoPerfil: AppUserType.professional,
          dadosProfissional: {
            'categorias': ['singer', 'instrumentalist'],
            'funcoes': ['audiovisual_direcao_de_video'],
            'instrumentos': ['Guitarra', 'Baixo'],
            'generosMusicais': ['Rock', 'Jazz'],
          },
        );

        expect(user.professionalCategories, ['singer', 'instrumentalist']);
        expect(user.professionalRoles, ['audiovisual_direcao_de_video']);
        expect(user.professionalInstruments, ['Guitarra', 'Baixo']);
        expect(user.professionalGenres, ['Rock', 'Jazz']);
      });

      test('professional list accessors return empty when missing', () {
        const user = AppUser(
          uid: 'pro-uid',
          email: 'pro@example.com',
          tipoPerfil: AppUserType.professional,
          dadosProfissional: {'nomeArtistico': 'DJ Test'},
        );

        expect(user.professionalCategories, isEmpty);
        expect(user.professionalRoles, isEmpty);
        expect(user.professionalInstruments, isEmpty);
        expect(user.professionalGenres, isEmpty);
      });

      test('professional list accessors trim and filter empty strings', () {
        const user = AppUser(
          uid: 'pro-uid',
          email: 'pro@example.com',
          tipoPerfil: AppUserType.professional,
          dadosProfissional: {
            'categorias': ['  singer  ', '', 'dj'],
          },
        );

        expect(user.professionalCategories, ['singer', 'dj']);
      });
    });

    group('appDisplayName regression', () {
      test('professional falls back to generic label when name is empty', () {
        const user = AppUser(
          uid: 'pro-uid',
          email: 'pro@example.com',
          tipoPerfil: AppUserType.professional,
          dadosProfissional: {},
        );

        expect(user.appDisplayName, 'Profissional');
      });

      test('band uses legacy fallback chain', () {
        const user = AppUser(
          uid: 'band-uid',
          email: 'band@example.com',
          tipoPerfil: AppUserType.band,
          dadosBanda: {'nome': 'Nome Legado'},
        );

        expect(user.appDisplayName, 'Nome Legado');
      });

      test('studio prefers nomeEstudio over legacy keys', () {
        const user = AppUser(
          uid: 'studio-uid',
          email: 'studio@example.com',
          tipoPerfil: AppUserType.studio,
          dadosEstudio: {
            'nomeEstudio': 'Studio Atual',
            'nomeArtistico': 'Legado Artistico',
            'nome': 'Legado Nome',
          },
        );

        expect(user.appDisplayName, 'Studio Atual');
      });

      test('contractor uses nomeExibicao', () {
        const user = AppUser(
          uid: 'contractor-uid',
          email: 'contractor@example.com',
          tipoPerfil: AppUserType.contractor,
          dadosContratante: {'nomeExibicao': 'Casa Show'},
        );

        expect(user.appDisplayName, 'Casa Show');
      });
    });

    group('avatar urls', () {
      test('prefers explicit fotoThumb for preview surfaces', () {
        const user = AppUser(
          uid: 'artist-uid',
          email: 'artist@example.com',
          foto: 'https://cdn.example.com/profile_photos/user/large.webp',
          fotoThumb:
              'https://cdn.example.com/profile_photos/user/thumbnail.webp',
        );

        expect(
          user.avatarPreviewUrl,
          'https://cdn.example.com/profile_photos/user/thumbnail.webp',
        );
        expect(
          user.avatarFullUrl,
          'https://cdn.example.com/profile_photos/user/large.webp',
        );
      });

      test('falls back to foto when fotoThumb is absent', () {
        const user = AppUser(
          uid: 'artist-uid',
          email: 'artist@example.com',
          foto:
              'https://firebasestorage.googleapis.com/v0/b/app/o/profile_photos%2Fartist-uid%2Flarge.webp?alt=media&token=abc',
        );

        expect(
          user.avatarPreviewUrl,
          'https://firebasestorage.googleapis.com/v0/b/app/o/profile_photos%2Fartist-uid%2Flarge.webp?alt=media&token=abc',
        );
        expect(
          user.avatarFullUrl,
          'https://firebasestorage.googleapis.com/v0/b/app/o/profile_photos%2Fartist-uid%2Flarge.webp?alt=media&token=abc',
        );
      });
    });
  });
}
