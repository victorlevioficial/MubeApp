import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/gigs/data/gig_repository.dart';
import 'package:mube/src/features/gigs/data/gig_search_index.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_draft.dart';
import 'package:mube/src/features/gigs/domain/gig_filters.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';

import '../../../helpers/firebase_mocks.dart';

void main() {
  late GigRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late User mockUser;

  const applicantId = 'applicant-1';
  const creatorId = 'creator-1';
  const gigId = 'gig-1';

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser(uid: applicantId);

    when(mockAuth.currentUser).thenReturn(mockUser);

    repository = GigRepository(
      fakeFirestore,
      mockAuth,
      const NoopAnalyticsService(),
    );

    await fakeFirestore.collection('users').doc(applicantId).set({
      'uid': applicantId,
      'email': 'applicant@mube.com',
      'cadastro_status': 'concluido',
    });

    await fakeFirestore.collection('users').doc(creatorId).set({
      'uid': creatorId,
      'email': 'creator@mube.com',
      'cadastro_status': 'concluido',
    });

    await fakeFirestore.collection('gigs').doc(gigId).set({
      'title': 'Preciso de guitarrista',
      'description': 'Gig de teste com detalhes suficientes para candidatura.',
      'gig_type': 'show_ao_vivo',
      'status': 'open',
      'date_mode': 'unspecified',
      'location_type': 'presencial',
      'genres': const <String>['rock'],
      'required_instruments': const <String>['guitarra'],
      'required_crew_roles': const <String>[],
      'required_studio_services': const <String>[],
      'slots_total': 2,
      'slots_filled': 0,
      'compensation_type': 'fixed',
      'compensation_value': 500,
      'creator_id': creatorId,
      'applicant_count': 0,
      'created_at': Timestamp.fromDate(DateTime(2026, 3, 9)),
      'updated_at': Timestamp.fromDate(DateTime(2026, 3, 9)),
    });
  });

  Future<void> seedGig(
    String id, {
    required String title,
    String status = 'open',
    String dateMode = 'unspecified',
    DateTime? gigDate,
    int slotsTotal = 2,
    int slotsFilled = 0,
    DateTime? createdAt,
  }) {
    return fakeFirestore.collection('gigs').doc(id).set({
      'title': title,
      'description': 'Gig de teste com detalhes suficientes para candidatura.',
      'gig_type': 'show_ao_vivo',
      'status': status,
      'date_mode': dateMode,
      'gig_date': gigDate == null ? null : Timestamp.fromDate(gigDate),
      'location_type': 'presencial',
      'genres': const <String>['rock'],
      'required_instruments': const <String>['guitarra'],
      'required_crew_roles': const <String>[],
      'required_studio_services': const <String>[],
      'slots_total': slotsTotal,
      'slots_filled': slotsFilled,
      'compensation_type': 'fixed',
      'compensation_value': 500,
      'creator_id': creatorId,
      'applicant_count': 0,
      'created_at': Timestamp.fromDate(createdAt ?? DateTime(2026, 3, 9)),
      'updated_at': Timestamp.fromDate(createdAt ?? DateTime(2026, 3, 9)),
      'search_grams': buildGigSearchGrams(
        title: title,
        description: 'Gig de teste com detalhes suficientes para candidatura.',
      ),
      'search_schema_version': gigSearchSchemaVersion,
    });
  }

  group('GigRepository.createGig', () {
    test('rejects a fixed date in the past', () async {
      final draft = GigDraft(
        title: 'Gig expirada',
        description: 'Uma descrição suficientemente detalhada para a vaga.',
        gigType: GigType.liveShow,
        dateMode: GigDateMode.fixedDate,
        gigDate: DateTime.now().subtract(const Duration(minutes: 1)),
        locationType: GigLocationType.onsite,
        slotsTotal: 1,
        compensationType: CompensationType.negotiable,
      );

      await expectLater(
        repository.createGig(draft),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('A data da gig precisa estar no futuro.'),
          ),
        ),
      );
    });
  });

  group('GigRepository.watchGigs', () {
    test(
      'does not hide an older match behind newer nonmatching gigs',
      () async {
        await fakeFirestore.collection('gigs').doc(gigId).delete();
        await Future.wait(
          List.generate(
            201,
            (index) => seedGig(
              'newer-$index',
              title: 'Gig sem o termo $index',
              createdAt: DateTime(2026, 4, 1).add(Duration(minutes: index)),
            ),
          ),
        );
        await seedGig(
          'older-match',
          title: 'Compatível antiga',
          createdAt: DateTime(2026, 3, 1),
        );

        final gigs = await repository
            .watchGigs(const GigFilters(term: 'compatível antiga'))
            .first;

        expect(gigs.map((gig) => gig.id), ['older-match']);
      },
    );

    test('uses the ready search index without losing older matches', () async {
      await fakeFirestore.collection('config').doc('app_data').set({
        'gig_search_schema_version': gigSearchSchemaVersion,
      });
      await fakeFirestore.collection('gigs').doc(gigId).delete();
      await Future.wait(
        List.generate(
          201,
          (index) => seedGig(
            'newer-indexed-$index',
            title: 'Vaga comum $index',
            createdAt: DateTime(2026, 4, 1).add(Duration(minutes: index)),
          ),
        ),
      );
      await seedGig(
        'older-sax',
        title: 'Procura-se saxofonista',
        createdAt: DateTime(2026, 3, 1),
      );

      final gigs = await repository
          .watchGigs(const GigFilters(term: 'SAXOFONÍSTA'))
          .first;

      expect(gigs.map((gig) => gig.id), ['older-sax']);
    });
  });

  group('GigRepository.watchLatestOpenGigs', () {
    test('skips gigs that are full or expired and keeps valid ones', () async {
      await fakeFirestore.collection('gigs').doc(gigId).delete();

      await seedGig(
        'gig-full',
        title: 'Gig lotada',
        slotsTotal: 1,
        slotsFilled: 1,
        createdAt: DateTime(2026, 3, 12),
      );
      await seedGig(
        'gig-expired',
        title: 'Gig expirada',
        dateMode: 'fixed_date',
        gigDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime(2026, 3, 11),
      );
      await seedGig(
        'gig-valid-1',
        title: 'Gig aberta 1',
        createdAt: DateTime(2026, 3, 10),
      );
      await seedGig(
        'gig-valid-2',
        title: 'Gig aberta 2',
        createdAt: DateTime(2026, 3, 9),
      );
      await seedGig(
        'gig-valid-3',
        title: 'Gig aberta 3',
        createdAt: DateTime(2026, 3, 8),
      );

      final gigs = await repository.watchLatestOpenGigs(limit: 3).first;

      expect(gigs.map((gig) => gig.title).toList(), <String>[
        'Gig aberta 1',
        'Gig aberta 2',
        'Gig aberta 3',
      ]);
    });
  });

  group('GigRepository.applyToGig', () {
    test('rejects applications after the fixed gig date', () async {
      await fakeFirestore.collection('gigs').doc(gigId).update({
        'date_mode': 'fixed_date',
        'gig_date': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      });

      await expectLater(
        repository.applyToGig(gigId, 'Ainda tenho interesse.'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('A data desta gig já passou.'),
          ),
        ),
      );
    });

    test('creates a pending application for the current user', () async {
      await repository.applyToGig(gigId, 'Tenho experiencia com palco.');

      final doc = await fakeFirestore
          .collection('gigs')
          .doc(gigId)
          .collection('gig_applications')
          .doc(applicantId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data(), containsPair('applicant_id', applicantId));
      expect(
        doc.data(),
        containsPair('message', 'Tenho experiencia com palco.'),
      );
      expect(doc.data(), containsPair('status', 'pending'));
      expect(doc.data(), contains('applied_at'));
    });

    test('creates a pending application without a message', () async {
      await repository.applyToGig(gigId, '');

      final doc = await fakeFirestore
          .collection('gigs')
          .doc(gigId)
          .collection('gig_applications')
          .doc(applicantId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data(), containsPair('applicant_id', applicantId));
      expect(doc.data(), containsPair('message', ''));
      expect(doc.data(), containsPair('status', 'pending'));
    });

    test(
      'throws a friendly error when an application already exists',
      () async {
        await fakeFirestore
            .collection('gigs')
            .doc(gigId)
            .collection('gig_applications')
            .doc(applicantId)
            .set({
              'applicant_id': applicantId,
              'message': 'Mensagem anterior',
              'status': 'pending',
              'applied_at': Timestamp.fromDate(DateTime(2026, 3, 9)),
              'responded_at': null,
            });

        expect(
          () => repository.applyToGig(gigId, 'Nova mensagem'),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Voce ja tem uma candidatura ativa para esta gig.'),
            ),
          ),
        );
      },
    );

    test(
      'ignores legacy documents with another id and creates the canonical application doc',
      () async {
        await fakeFirestore
            .collection('gigs')
            .doc(gigId)
            .collection('gig_applications')
            .doc('legacy-doc')
            .set({
              'applicant_id': applicantId,
              'message': 'Mensagem legado',
              'status': 'pending',
              'applied_at': Timestamp.fromDate(DateTime(2026, 3, 9)),
              'responded_at': null,
            });

        await repository.applyToGig(gigId, 'Nova candidatura');

        final canonicalDoc = await fakeFirestore
            .collection('gigs')
            .doc(gigId)
            .collection('gig_applications')
            .doc(applicantId)
            .get();

        expect(canonicalDoc.exists, isTrue);
        expect(canonicalDoc.data(), containsPair('applicant_id', applicantId));
        expect(
          canonicalDoc.data(),
          containsPair('message', 'Nova candidatura'),
        );
      },
    );
  });

  group('GigRepository.hasApplied', () {
    test('returns false when the current user has no application', () async {
      expect(await repository.hasApplied(gigId), isFalse);
    });

    test('returns true when the current user already applied', () async {
      await fakeFirestore
          .collection('gigs')
          .doc(gigId)
          .collection('gig_applications')
          .doc(applicantId)
          .set({
            'applicant_id': applicantId,
            'message': 'Mensagem anterior',
            'status': 'pending',
            'applied_at': Timestamp.fromDate(DateTime(2026, 3, 9)),
            'responded_at': null,
          });

      expect(await repository.hasApplied(gigId), isTrue);
    });

    test(
      'returns false when only a legacy non-canonical document exists',
      () async {
        await fakeFirestore
            .collection('gigs')
            .doc(gigId)
            .collection('gig_applications')
            .doc('legacy-doc')
            .set({
              'applicant_id': applicantId,
              'message': 'Mensagem anterior',
              'status': 'pending',
              'applied_at': Timestamp.fromDate(DateTime(2026, 3, 9)),
              'responded_at': null,
            });

        expect(await repository.hasApplied(gigId), isFalse);
      },
    );
  });
}
