import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../features/auth/domain/app_user.dart';
import '../features/auth/domain/user_type.dart';
import '../features/profile/domain/media_item.dart';

class DatabaseSeeder {
  static const _uuid = Uuid();
  static final _faker = Faker();
  static final _random = Random();

  static Future<void> testConnection() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final projectId = firestore.app.options.projectId;
    final currentUser = auth.currentUser;

    print('🧪 Testando conexão básica com Firestore...');
    print('🆔 Project ID ativo no App: $projectId');
    print('👤 Usuário Autenticado: ${currentUser?.uid ?? 'NENHUM'}');
    try {
      final ref = firestore.collection('test_connection').doc('check');
      await ref.set({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'ok',
      });
      print('✅ Conexão básica OK! O Firebase está recebendo seus dados.');
      await ref.delete();
    } catch (e) {
      print('❌ FALHA TOTAL DE CONEXÃO: $e');
      rethrow;
    }
  }

  /// URLs de imagens públicas para avatares (Pravatar e UI Faces)
  static final List<String> _avatarUrls = List.generate(
    50,
    (index) => 'https://i.pravatar.cc/400?u=${_random.nextInt(1000)}',
  );

  /// URLs de imagens para galeria (Picsum e Unsplash)
  static String _getRandomPhotoUrl(int width, int height) {
    final id = _random.nextInt(1000);
    return 'https://picsum.photos/id/$id/$width/$height';
  }

  /// URLs de vídeos de teste (mp4 públicos)
  static final List<String> _videoUrls = [
    'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
  ];

  static Future<void> seedUsers({int count = 50}) async {
    final firestore = FirebaseFirestore.instance;

    print('🌱 Iniciando Seed de $count usuários...');

    try {
      for (int i = 0; i < count; i++) {
        final user = _generateFakeUser();

        await firestore.collection('users').doc(user.uid).set({
          ...user.toFirestore(),
          'isMock': true,
        });

        if (i % 5 == 0) {
          print('✅ Gerados ${i + 1}/$count usuários');
        }
      }
      print('🚀 Seed concluído com sucesso!');
    } catch (e) {
      print('❌ ERRO AO EXECUTAR SEED: $e');
      rethrow;
    }
  }

  static Future<void> clearMockUsers() async {
    final firestore = FirebaseFirestore.instance;
    const batchLimit = 500;

    print('🧹 Iniciando limpeza de usuários mock...');

    try {
      // Busca todos usuários marcados como isMock
      final snapshot = await firestore
          .collection('users')
          .where('isMock', isEqualTo: true)
          .limit(batchLimit)
          .get();

      if (snapshot.docs.isEmpty) {
        print('✅ Nenhum usuário mock encontrado.');
        return;
      }

      print('🗑️ Encontrados ${snapshot.docs.length} usuários para deletar...');
      await _deleteBatch(firestore, snapshot.docs);

      if (snapshot.docs.length == batchLimit) {
        await clearMockUsers();
      } else {
        print('✨ Limpeza concluída!');
      }
    } catch (e) {
      print('❌ ERRO AO LIMPAR MOCKS: $e');
      print(
        'DICA: Verifique se as regras do Firestore permitem leitura/escrita pública.',
      );
      rethrow;
    }
  }

  static Future<void> _deleteBatch(
    FirebaseFirestore firestore,
    List<DocumentSnapshot> docs,
  ) async {
    final batch = firestore.batch();
    for (final doc in docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static AppUser _generateFakeUser() {
    final uid = _uuid.v4();
    final type = AppUserType.values[_random.nextInt(AppUserType.values.length)];
    final city = _cities[_random.nextInt(_cities.length)];
    final String firstName = _faker.person.firstName();
    final String lastName = _faker.person.lastName();
    final String name = type == AppUserType.band
        ? 'Banda ${_faker.company.name()}'
        : '$firstName $lastName';

    // Gera galeria aleatória (3 a 9 itens)
    final gallery = _generateGallery();

    // Mapas vazios para outros tipos
    Map<String, dynamic>? dadosProfissional;
    Map<String, dynamic>? dadosBanda;
    Map<String, dynamic>? dadosEstudio;
    Map<String, dynamic>? dadosContratante;

    // Preenche dados específicos baseados no tipo
    switch (type) {
      case AppUserType.professional:
        dadosProfissional = {
          'gallery': gallery.map((e) => e.toJson()).toList(),
          'nomeArtistico': firstName, // Usado como fallback se necessário
          'instrumentos': _getRandomSkills(),
          'funcoes': ['Músico'],
          'generosMusicais': _getRandomGenres(),
          'cache': 'R\$ ${_random.nextInt(500) + 100},00',
        };
        break;
      case AppUserType.band:
        dadosBanda = {
          'gallery': gallery.map((e) => e.toJson()).toList(),
          'nomeBanda': name,
          'generosMusicais': _getRandomGenres(),
          'members': _random.nextInt(6) + 2,
        };
        break;
      case AppUserType.studio:
        dadosEstudio = {
          'gallery': gallery.map((e) => e.toJson()).toList(),
          'nomeArtistico': 'Estúdio $firstName',
          'services': ['Gravação', 'Mixagem', 'Masterização'],
          'equipments': ['Microfone Neumann', 'Mesa Behringer', 'Pro Tools'],
          'hourRate': 'R\$ ${_random.nextInt(200) + 50}/h',
        };
        break;
      case AppUserType.contractor:
        dadosContratante = {
          'gallery': gallery.map((e) => e.toJson()).toList(),
          'venueType': _random.nextBool() ? 'Bar' : 'Events Hall',
          'capacity': (_random.nextInt(10) + 1) * 100,
        };
        break;
    }

    return AppUser(
      uid: uid,
      email: _faker.internet.email(),
      nome: name,
      bio: _faker.lorem.sentences(2).join(' '),
      foto: _avatarUrls[_random.nextInt(_avatarUrls.length)],
      tipoPerfil: type,
      cadastroStatus: 'concluido',
      status: 'ativo',
      location: {
        'cidade': city.name,
        'estado': city.state,
        'lat':
            city.lat + (_random.nextDouble() - 0.5) * 0.02, // Pequena variação
        'lng': city.lng + (_random.nextDouble() - 0.5) * 0.02,
      },
      dadosProfissional: dadosProfissional,
      dadosBanda: dadosBanda,
      dadosEstudio: dadosEstudio,
      dadosContratante: dadosContratante,
      createdAt: FieldValue.serverTimestamp(),
    );
  }

  static List<MediaItem> _generateGallery() {
    final count = _random.nextInt(7) + 3; // 3 to 9 items
    final items = <MediaItem>[];

    for (int i = 0; i < count; i++) {
      final isVideo = _random.nextDouble() < 0.3; // 30% chance de vídeo
      final id = _uuid.v4();

      if (isVideo) {
        items.add(
          MediaItem(
            id: id,
            url: _videoUrls[_random.nextInt(_videoUrls.length)],
            type: MediaType.video,
            thumbnailUrl: _getRandomPhotoUrl(400, 400),
            order: i,
          ),
        );
      } else {
        // Alterna entre quadrado, retrato e paisagem
        final aspect = _random.nextInt(3);
        int w = 800, h = 800;
        if (aspect == 1) {
          w = 600;
          h = 800;
        } // Portrait
        if (aspect == 2) {
          w = 800;
          h = 600;
        } // Landscape

        items.add(
          MediaItem(
            id: id,
            url: _getRandomPhotoUrl(w, h),
            type: MediaType.photo,
            order: i,
          ),
        );
      }
    }
    return items;
  }

  static List<String> _getRandomSkills() {
    final skills = [
      'Guitarra',
      'Bateria',
      'Baixo',
      'Vocal',
      'Roadie',
      'Técnico de Som',
      'Luz',
    ];
    skills.shuffle();
    return skills.take(_random.nextInt(3) + 1).toList();
  }

  static List<String> _getRandomGenres() {
    final genres = ['Rock', 'Pop', 'Jazz', 'Samba', 'MPB', 'Metal', 'Blues'];
    genres.shuffle();
    return genres.take(_random.nextInt(3) + 1).toList();
  }

  static final List<_CityData> _cities = [
    const _CityData('São Paulo', 'SP', -23.5505, -46.6333),
    const _CityData('Rio de Janeiro', 'RJ', -22.9068, -43.1729),
    const _CityData('Belo Horizonte', 'MG', -19.9167, -43.9345),
    const _CityData('Salvador', 'BA', -12.9774, -38.5016),
    const _CityData('Brasília', 'DF', -15.7975, -47.8919),
    const _CityData('Curitiba', 'PR', -25.4284, -49.2733),
    const _CityData('Fortaleza', 'CE', -3.7172, -38.5434),
    const _CityData('Manaus', 'AM', -3.1190, -60.0217),
    const _CityData('Recife', 'PE', -8.0543, -34.8813),
    const _CityData('Porto Alegre', 'RS', -30.0346, -51.2177),
    const _CityData('Belém', 'PA', -1.4558, -48.5044),
    const _CityData('Goiânia', 'GO', -16.6869, -49.2648),
    const _CityData('Florianópolis', 'SC', -27.5954, -48.5480),
    const _CityData('Vitória', 'ES', -20.3155, -40.3128),
    const _CityData('Natal', 'RN', -5.7945, -35.2110),
  ];
}

class _CityData {
  final String name;
  final String state;
  final double lat;
  final double lng;

  const _CityData(this.name, this.state, this.lat, this.lng);
}
