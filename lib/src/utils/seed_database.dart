import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/domain/user_type.dart';
import '../features/profile/domain/media_item.dart';
import 'app_logger.dart';
import 'geohash_helper.dart';

/// Advanced Database Seeder v3.0
/// Generates 100 ultra-realistic, diverse professional profiles with:
/// - Multi-category support (singer + instrumentalist + crew combinations)
/// - Proper lng field naming
/// - Brazilian geographic diversity
/// - Thematic musical profiles
class DatabaseSeeder {
  static const _uuid = Uuid();
  static final _faker = Faker();
  static final _random = Random();

  // Brazilian Cities with Real Coordinates
  static final List<Map<String, dynamic>> _brazilianCities = [
    {'city': 'São Paulo', 'state': 'SP', 'lat': -23.5505, 'lng': -46.6333},
    {'city': 'Rio de Janeiro', 'state': 'RJ', 'lat': -22.9068, 'lng': -43.1729},
    {'city': 'Belo Horizonte', 'state': 'MG', 'lat': -19.9167, 'lng': -43.9345},
    {'city': 'Porto Alegre', 'state': 'RS', 'lat': -30.0346, 'lng': -51.2177},
    {'city': 'Salvador', 'state': 'BA', 'lat': -12.9714, 'lng': -38.5014},
    {'city': 'Brasília', 'state': 'DF', 'lat': -15.8267, 'lng': -47.9218},
    {'city': 'Curitiba', 'state': 'PR', 'lat': -25.4284, 'lng': -49.2733},
    {'city': 'Recife', 'state': 'PE', 'lat': -8.0476, 'lng': -34.8770},
    {'city': 'Fortaleza', 'state': 'CE', 'lat': -3.7172, 'lng': -38.5433},
    {'city': 'Manaus', 'state': 'AM', 'lat': -3.1190, 'lng': -60.0217},
  ];

  // Musical Profiles (Thematic Combinations)
  static final List<Map<String, dynamic>> _musicalProfiles = [
    {
      'name': 'Roqueiro Raiz',
      'genres': ['Rock', 'Blues', 'Metal'],
      'categories': ['singer', 'instrumentalist'],
      'instruments': ['Guitarra', 'Violão'],
    },
    {
      'name': 'Sertanejo',
      'genres': ['Sertanejo', 'Country'],
      'categories': ['singer'],
      'instruments': [],
    },
    {
      'name': 'Jazzista',
      'genres': ['Jazz', 'Blues', 'Soul'],
      'categories': ['instrumentalist'],
      'instruments': ['Saxofone', 'Piano'],
    },
    {
      'name': 'Funkeiro',
      'genres': ['Funk', 'Hip Hop', 'Rap'],
      'categories': ['singer', 'dj'],
      'instruments': [],
    },
    {
      'name': 'Músico de Orquestra',
      'genres': ['Jazz', 'MPB'],
      'categories': ['instrumentalist'],
      'instruments': ['Violino', 'Viola', 'Cello'],
    },
    {
      'name': 'Pagodeiro',
      'genres': ['Pagode', 'Samba'],
      'categories': ['singer', 'instrumentalist'],
      'instruments': ['Cavaquinho', 'Violão', 'Percussão'],
    },
    {
      'name': 'DJ Eletrônico',
      'genres': ['Eletrônica', 'Pop'],
      'categories': ['dj'],
      'instruments': [],
    },
    {
      'name': 'Técnico Profissional',
      'genres': ['Rock', 'Pop', 'Eletrônica'],
      'categories': ['crew'],
      'instruments': [],
    },
    {
      'name': 'Multi-instrumentista',
      'genres': ['MPB', 'Jazz', 'Pop'],
      'categories': ['instrumentalist', 'crew'],
      'instruments': ['Piano', 'Bateria', 'Baixo'],
    },
    {
      'name': 'Cantor Gospel',
      'genres': ['Gospel', 'Pop'],
      'categories': ['singer'],
      'instruments': [],
    },
  ];

  /// URLs de imagens públicas para avatares
  static final List<String> _avatarUrls = List.generate(
    50,
    (index) => 'https://i.pravatar.cc/400?u=${_random.nextInt(1000)}',
  );

  /// URLs de imagens para galeria
  static String _getRandomPhotoUrl(int width, int height) {
    final id = _random.nextInt(1000);
    return 'https://picsum.photos/id/$id/$width/$height';
  }

  /// URLs de vídeos de teste
  static final List<String> _videoUrls = [
    'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  ];

  static Future<void> testConnection() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final projectId = firestore.app.options.projectId;
    final currentUser = auth.currentUser;

    AppLogger.info('🧪 Testando conexão básica com Firestore...');
    AppLogger.info('🆔 Project ID ativo no App: $projectId');
    AppLogger.info('👤 Usuário Autenticado: ${currentUser?.uid ?? 'NENHUM'}');
    try {
      final ref = firestore.collection('test_connection').doc('check');
      await ref.set({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'ok',
      });
      AppLogger.info(
        '✅ Conexão básica OK! O Firebase está recebendo seus dados.',
      );
      await ref.delete();
    } catch (e) {
      AppLogger.error('❌ FALHA TOTAL DE CONEXÃO', e);
      rethrow;
    }
  }

  static Future<void> seedUsers({int count = 100}) async {
    final firestore = FirebaseFirestore.instance;

    AppLogger.info('🌱 Iniciando Seed de $count usuários realistas...');

    try {
      for (int i = 0; i < count; i++) {
        final user = _generateRealisticUser(index: i);

        await firestore.collection('users').doc(user.uid).set({
          ...user.toFirestore(),
          'isMock': true,
        });

        if (i % 10 == 0 || i == count - 1) {
          AppLogger.info('✅ Gerados ${i + 1}/$count usuários');
        }
      }
      AppLogger.info(
        '🚀 Seed concluído com sucesso! Perfis multi-categoria criados.',
      );
    } catch (e) {
      AppLogger.error('❌ ERRO AO EXECUTAR SEED', e);
      rethrow;
    }
  }

  static Future<void> clearMockUsers() async {
    final firestore = FirebaseFirestore.instance;
    const batchLimit = 500;

    AppLogger.info('🧹 Iniciando limpeza de usuários mock...');

    try {
      final snapshot = await firestore
          .collection('users')
          .where('isMock', isEqualTo: true)
          .limit(batchLimit)
          .get();

      if (snapshot.docs.isEmpty) {
        AppLogger.info('ℹ️ Nenhum usuário mock encontrado.');
        return;
      }

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      AppLogger.info(
        '🗑️ ${snapshot.docs.length} usuários mock removidos com sucesso!',
      );
    } catch (e) {
      AppLogger.error('❌ ERRO AO LIMPAR MOCKS', e);
      rethrow;
    }
  }

  // ========== HELPER FUNCTIONS ==========

  static Map<String, dynamic> _generateBrazilianLocation() {
    final city = _brazilianCities[_random.nextInt(_brazilianCities.length)];

    // Add small random variation to coordinates (±0.05 degrees)
    double variation() => (_random.nextDouble() - 0.5) * 0.1;

    final lat = (city['lat'] as double) + variation();
    final lng = (city['lng'] as double) + variation();

    // Generate geohash for efficient spatial queries (precision 5 = ~5km)
    final geohash = GeohashHelper.encode(lat, lng, precision: 5);

    return {
      'cidade': city['city'],
      'estado': city['state'],
      'lat': lat,
      'lng': lng,
      'geohash': geohash, // NEW: for optimized location queries
      'cep': '${_random.nextInt(90000) + 10000}-${_random.nextInt(900) + 100}',
      'logradouro': 'Rua ${_faker.address.streetName()}',
      'numero': '${_random.nextInt(9000) + 100}',
      'bairro': _faker.address.neighborhood(),
    };
  }

  static List<String> _pickCategories(int index) {
    // Weighted distribution:
    // 60% mono-category, 30% duo-category, 10% tri-category

    if (index < 60) {
      // Mono-category
      if (index < 25) return ['singer'];
      if (index < 45) return ['instrumentalist'];
      if (index < 55) return ['crew'];
      return ['dj'];
    } else if (index < 90) {
      // Duo-category
      if (index < 70) return ['singer', 'instrumentalist'];
      if (index < 80) return ['instrumentalist', 'crew'];
      if (index < 85) return ['singer', 'dj'];
      return ['instrumentalist', 'dj'];
    } else {
      // Tri-category
      if (index < 95) return ['singer', 'instrumentalist', 'crew'];
      return ['instrumentalist', 'crew', 'dj'];
    }
  }

  static List<String> _pickGenres(List<String> categories) {
    // Pick a thematic profile or random genres
    if (_random.nextDouble() < 0.7) {
      // 70% use thematic profiles
      final profile =
          _musicalProfiles[_random.nextInt(_musicalProfiles.length)];
      return List<String>.from(profile['genres']);
    } else {
      // 30% completely random
      final count = _random.nextInt(2) + 2; // 2-3 genres
      final selected = <String>{};
      while (selected.length < count) {
        selected.add(genres[_random.nextInt(genres.length)]);
      }
      return selected.toList();
    }
  }

  static List<String> _pickInstruments() {
    final count = _random.nextInt(2) + 1; // 1-2 instruments
    final selected = <String>{};
    while (selected.length < count) {
      selected.add(instruments[_random.nextInt(instruments.length)]);
    }
    return selected.toList();
  }

  static List<String> _pickCrewRoles() {
    final count = _random.nextInt(2) + 1; // 1-2 roles
    final selected = <String>{};
    while (selected.length < count) {
      selected.add(crewRoles[_random.nextInt(crewRoles.length)]);
    }
    return selected.toList();
  }

  static Map<String, dynamic> _buildProfessionalData(List<String> categories) {
    final selectedGenres = _pickGenres(categories);

    final data = <String, dynamic>{
      'nomeArtistico': _faker.person.name(),
      'celular':
          '(${_random.nextInt(90) + 10}) ${_random.nextInt(90000) + 10000}-${_random.nextInt(9000) + 1000}',
      'dataNascimento':
          '${_random.nextInt(20) + 5}/${_random.nextInt(12) + 1}/${_random.nextInt(25) + 1975}',
      'genero': [
        'Masculino',
        'Feminino',
        'Outro',
        'Prefiro não dizer',
      ][_random.nextInt(4)],
      'instagram': '@${_faker.internet.userName().toLowerCase()}',
      'categorias': categories, // ARRAY, not string!
      'generosMusicais': selectedGenres,
      'isPublic': true,
    };

    // Singer attributes
    if (categories.contains('singer')) {
      final modes = ['0', '1', '2'];
      final weights = [0.4, 0.4, 0.2]; // 40%, 40%, 20%
      final rand = _random.nextDouble();
      String mode;
      if (rand < weights[0]) {
        mode = modes[0];
      } else if (rand < weights[0] + weights[1]) {
        mode = modes[1];
      } else {
        mode = modes[2];
      }
      data['backingVocalMode'] = mode;
    }

    // Instrumentalist attributes
    if (categories.contains('instrumentalist')) {
      data['instrumentos'] = _pickInstruments();
      data['fazBackingVocal'] = _random.nextDouble() < 0.3; // 30% chance
    }

    // Crew attributes
    if (categories.contains('crew')) {
      data['funcoes'] = _pickCrewRoles();
    }

    return data;
  }

  static AppUser _generateRealisticUser({required int index}) {
    final uid = _uuid.v4();
    final location = _generateBrazilianLocation();
    final categories = _pickCategories(index);
    final professionalData = _buildProfessionalData(categories);

    // Generate gallery with 2-5 items
    final galleryCount = _random.nextInt(4) + 2;
    final gallery = List.generate(galleryCount, (i) {
      final isPhoto = _random.nextBool();
      return MediaItem(
        id: _uuid.v4(),
        url: isPhoto
            ? _getRandomPhotoUrl(800, 600)
            : _videoUrls[_random.nextInt(_videoUrls.length)],
        type: isPhoto ? MediaType.photo : MediaType.video,
        thumbnailUrl: isPhoto ? null : _getRandomPhotoUrl(400, 300),
        order: i,
      );
    });

    return AppUser(
      uid: uid,
      email: '${uid.substring(0, 8)}@mock.com',
      cadastroStatus: 'concluido',
      tipoPerfil: AppUserType.professional,
      status: 'ativo',
      nome: professionalData['nomeArtistico'],
      foto: _avatarUrls[_random.nextInt(_avatarUrls.length)],
      bio: _faker.lorem.sentence(),
      location: location,
      geohash: location['geohash'], // For efficient spatial queries
      dadosProfissional: professionalData,
      createdAt: FieldValue.serverTimestamp(),
    );
  }
}
