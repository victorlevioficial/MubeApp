import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/search/data/search_repository.dart';
import 'package:mube/src/features/search/domain/search_filters.dart';
import 'package:mube/src/utils/professional_profile_utils.dart';

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
          'instrumentos': ['guitar'],
        },
        'created_at': Timestamp.now(),
      });

      await fakeFirestore.collection('users').doc('band-1').set({
        'nome': 'Banda Rock',
        'tipo_perfil': 'banda',
        'cadastro_status': 'concluido',
        'status': 'ativo',
        'banda': {
          'nomeBanda': 'Banda Rock',
          'generosMusicais': ['rock'],
        },
        'created_at': Timestamp.now(),
      });

      await fakeFirestore.collection('users').doc('studio-1').set({
        'nome': 'Studio Mix',
        'tipo_perfil': 'estudio',
        'cadastro_status': 'concluido',
        'status': 'ativo',
        'estudio': {
          'nomeEstudio': 'Studio Mix',
          'services': ['recording', 'mixing'],
          'studioType': 'commercial',
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
        expect(r.items.length, 1);
        expect(r.items.first.uid, userUid);
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
        expect(r.items.any((u) => u.uid == 'hidden-user'), false);
        expect(r.items.any((u) => u.uid == userUid), true);
      });
    });

    test(
      'professional-only filters under all should return only professionals',
      () async {
        const filters = SearchFilters(instruments: ['guitar']);

        final result = await repository.searchUsers(
          filters: filters,
          requestId: 3,
          getCurrentRequestId: () => 3,
        );

        result.fold((l) => fail('Should not fail'), (r) {
          expect(r.items.map((item) => item.uid), [userUid]);
        });
      },
    );

    test('studio-only filters under all should return only studios', () async {
      const filters = SearchFilters(
        services: ['recording'],
        studioType: 'commercial',
      );

      final result = await repository.searchUsers(
        filters: filters,
        requestId: 4,
        getCurrentRequestId: () => 4,
      );

      result.fold((l) => fail('Should not fail'), (r) {
        expect(r.items.map((item) => item.uid), ['studio-1']);
      });
    });

    test('conflicting type filters under all should return empty', () async {
      const filters = SearchFilters(
        instruments: ['guitar'],
        services: ['recording'],
      );

      final result = await repository.searchUsers(
        filters: filters,
        requestId: 5,
        getCurrentRequestId: () => 5,
      );

      result.fold((l) => fail('Should not fail'), (r) {
        expect(r.items, isEmpty);
        expect(r.hasMore, false);
      });
    });

    test(
      'should match legacy crew profile when filtering production',
      () async {
        await fakeFirestore.collection('users').doc('producer-1').set({
          'nome': 'Produtor',
          'tipo_perfil': 'profissional',
          'cadastro_status': 'concluido',
          'status': 'ativo',
          'profissional': {
            'nomeArtistico': 'Produtor Legacy',
            'categorias': ['crew'],
            'funcoes': ['Diretor Musical'],
            'generosMusicais': ['rock'],
          },
          'created_at': Timestamp.now(),
        });

        const filters = SearchFilters(
          category: SearchCategory.professionals,
          professionalSubcategory: ProfessionalSubcategory.production,
        );

        final result = await repository.searchUsers(
          filters: filters,
          requestId: 6,
          getCurrentRequestId: () => 6,
        );

        result.fold((l) => fail('Should not fail'), (r) {
          expect(r.items.map((item) => item.uid), contains('producer-1'));
        });
      },
    );

    test(
      'should match legacy crew profile when filtering stage tech',
      () async {
        await fakeFirestore.collection('users').doc('tech-1').set({
          'nome': 'Tecnico',
          'tipo_perfil': 'profissional',
          'cadastro_status': 'concluido',
          'status': 'ativo',
          'profissional': {
            'nomeArtistico': 'Tecnico Legacy',
            'categorias': ['crew'],
            'funcoes': ['Backline Tech'],
            'generosMusicais': ['rock'],
          },
          'created_at': Timestamp.now(),
        });

        const filters = SearchFilters(
          category: SearchCategory.professionals,
          professionalSubcategory: ProfessionalSubcategory.stageTech,
        );

        final result = await repository.searchUsers(
          filters: filters,
          requestId: 7,
          getCurrentRequestId: () => 7,
        );

        result.fold((l) => fail('Should not fail'), (r) {
          expect(r.items.map((item) => item.uid), contains('tech-1'));
        });
      },
    );

    test(
      'should filter only production profiles with remote recording',
      () async {
        await fakeFirestore.collection('users').doc('producer-remote').set({
          'nome': 'Produtora Remota',
          'tipo_perfil': 'profissional',
          'cadastro_status': 'concluido',
          'status': 'ativo',
          'profissional': {
            'nomeArtistico': 'Produtora Remota',
            'categorias': ['production'],
            professionalRemoteRecordingFieldKey: true,
            'funcoes': ['Diretor Musical'],
          },
          'created_at': Timestamp.now(),
        });

        await fakeFirestore.collection('users').doc('producer-local').set({
          'nome': 'Produtora Local',
          'tipo_perfil': 'profissional',
          'cadastro_status': 'concluido',
          'status': 'ativo',
          'profissional': {
            'nomeArtistico': 'Produtora Local',
            'categorias': ['production'],
            professionalRemoteRecordingFieldKey: false,
            'funcoes': ['Diretor Musical'],
          },
          'created_at': Timestamp.now(),
        });

        await fakeFirestore.collection('users').doc('stage-tech-remote').set({
          'nome': 'Tecnico Remoto',
          'tipo_perfil': 'profissional',
          'cadastro_status': 'concluido',
          'status': 'ativo',
          'profissional': {
            'nomeArtistico': 'Tecnico Remoto',
            'categorias': ['stage_tech'],
            professionalRemoteRecordingFieldKey: true,
            'funcoes': ['Backline Tech'],
          },
          'created_at': Timestamp.now(),
        });

        const filters = SearchFilters(
          category: SearchCategory.professionals,
          professionalSubcategory: ProfessionalSubcategory.production,
          offersRemoteRecording: true,
        );

        final result = await repository.searchUsers(
          filters: filters,
          requestId: 8,
          getCurrentRequestId: () => 8,
        );

        result.fold((l) => fail('Should not fail'), (r) {
          expect(r.items.map((item) => item.uid), contains('producer-remote'));
          expect(
            r.items.map((item) => item.uid),
            isNot(contains('producer-local')),
          );
          expect(
            r.items.map((item) => item.uid),
            isNot(contains('stage-tech-remote')),
          );
        });
      },
    );
  });
}
