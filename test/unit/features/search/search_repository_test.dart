import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/search/data/search_repository.dart';
import 'package:mube/src/features/search/domain/search_filters.dart';

import 'search_repository_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AnalyticsService>()])
void main() {
  late SearchRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAnalytics = MockAnalyticsService();
    repository = SearchRepository(
      firestore: fakeFirestore,
      analytics: mockAnalytics,
    );
  });

  group('SearchRepository', () {
    const userUid = 'user-1';

    setUp(() async {
      // Setup a valid searchable user
      await fakeFirestore.collection('users').doc(userUid).set({
        'nome': 'João Silva',
        'tipo_perfil': 'profissional',
        'cadastro_status': 'concluido',
        'status': 'ativo',
        'profissional': {
          'nomeArtistico': 'João Rockstar',
          'categorias': ['singer'],
          'generosMusicais': ['rock', 'pop'],
        },
        'created_at': Timestamp.now(),
      });
    });

    test('searchUsers should return list of matching users', () async {
      const filters = SearchFilters(term: 'João');

      final result = await repository.searchUsers(
        filters: filters,
        requestId: 1,
        getCurrentRequestId: () => 1,
      );

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not fail'), (r) {
        expect(r.length, 1);
        expect(r.first.uid, userUid);
      });
    });

    test('should filter out hidden profiles (Ghost Mode)', () async {
      // Add hidden user
      await fakeFirestore.collection('users').doc('hidden-user').set({
        'nome': 'Hidden User',
        'tipo_perfil': 'profissional',
        'cadastro_status': 'concluido',
        'status': 'ativo',
        'privacy_settings': {'visible_in_home': false},
        'created_at': Timestamp.now(),
      });

      final result = await repository.searchUsers(
        filters: const SearchFilters(),
        requestId: 2,
        getCurrentRequestId: () => 2,
      );

      result.fold((l) => fail('Should not fail'), (r) {
        expect(r.any((u) => u.uid == 'hidden-user'), false);
        expect(r.any((u) => u.uid == userUid), true);
      });
    });
  });
}
