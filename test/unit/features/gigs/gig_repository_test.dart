import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/features/gigs/data/gig_repository.dart';

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

    repository = GigRepository(fakeFirestore, mockAuth);

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

  group('GigRepository.applyToGig', () {
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

  group('GigRepository.watchMyApplications', () {
    test('returns applications sorted by appliedAt descending', () async {
      await fakeFirestore.collection('gigs').doc('gig-2').set({
        'title': 'Preciso de baixista',
        'description': 'Outra gig de teste com detalhes suficientes.',
        'gig_type': 'show_ao_vivo',
        'status': 'open',
        'date_mode': 'unspecified',
        'location_type': 'presencial',
        'genres': const <String>['rock'],
        'required_instruments': const <String>['baixo'],
        'required_crew_roles': const <String>[],
        'required_studio_services': const <String>[],
        'slots_total': 1,
        'slots_filled': 0,
        'compensation_type': 'fixed',
        'compensation_value': 700,
        'creator_id': creatorId,
        'applicant_count': 0,
        'created_at': Timestamp.fromDate(DateTime(2026, 3, 10)),
        'updated_at': Timestamp.fromDate(DateTime(2026, 3, 10)),
      });

      await fakeFirestore
          .collection('gigs')
          .doc(gigId)
          .collection('gig_applications')
          .doc(applicantId)
          .set({
            'applicant_id': applicantId,
            'message': 'Mensagem antiga',
            'status': 'pending',
            'applied_at': Timestamp.fromDate(DateTime(2026, 3, 9, 10)),
            'responded_at': null,
          });

      await fakeFirestore
          .collection('gigs')
          .doc('gig-2')
          .collection('gig_applications')
          .doc(applicantId)
          .set({
            'applicant_id': applicantId,
            'message': 'Mensagem mais recente',
            'status': 'accepted',
            'applied_at': Timestamp.fromDate(DateTime(2026, 3, 10, 12)),
            'responded_at': null,
          });

      final applications = await repository.watchMyApplications().first;

      expect(applications.map((application) => application.gigId), [
        'gig-2',
        gigId,
      ]);
      expect(applications.map((application) => application.gigTitle), [
        'Preciso de baixista',
        'Preciso de guitarrista',
      ]);
    });
  });
}
