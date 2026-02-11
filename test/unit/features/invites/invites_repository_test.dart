import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/features/bands/data/invites_repository.dart';

@GenerateMocks([FirebaseFunctions, HttpsCallable, HttpsCallableResult])
import 'invites_repository_test.mocks.dart';

void main() {
  late InvitesRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult<dynamic> mockResult;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult<dynamic>();

    when(mockResult.data).thenReturn({'success': true});
    when(mockCallable.call<dynamic>(any)).thenAnswer((_) async => mockResult);

    repository = InvitesRepository(mockFunctions, fakeFirestore);
  });

  group('InvitesRepository', () {
    group('sendInvite', () {
      test('should call manageBandInvite with send action', () async {
        // Arrange
        when(
          mockFunctions.httpsCallable('manageBandInvite'),
        ).thenReturn(mockCallable);

        // Act
        await repository.sendInvite(
          bandId: 'band-1',
          targetUid: 'user-2',
          targetName: 'John Doe',
          targetPhoto: 'https://photo.jpg',
          targetInstrument: 'Guitarra',
        );

        // Assert
        verify(mockFunctions.httpsCallable('manageBandInvite')).called(1);
        verify(
          mockCallable.call<dynamic>({
            'action': 'send',
            'bandId': 'band-1',
            'targetUid': 'user-2',
            'targetName': 'John Doe',
            'targetPhoto': 'https://photo.jpg',
            'targetInstrument': 'Guitarra',
          }),
        ).called(1);
      });

      test('should throw exception on error', () async {
        // Arrange
        when(
          mockFunctions.httpsCallable('manageBandInvite'),
        ).thenReturn(mockCallable);
        when(
          mockCallable.call<dynamic>(any),
        ).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.sendInvite(
            bandId: 'band-1',
            targetUid: 'user-2',
            targetName: 'John Doe',
            targetPhoto: 'https://photo.jpg',
            targetInstrument: 'Guitarra',
          ),
          throwsException,
        );
      });
    });

    group('respondToInvite', () {
      test('should call manageBandInvite with accept action', () async {
        // Arrange
        when(
          mockFunctions.httpsCallable('manageBandInvite'),
        ).thenReturn(mockCallable);

        // Act
        await repository.respondToInvite(inviteId: 'invite-1', accept: true);

        // Assert
        verify(
          mockCallable.call<dynamic>({
            'action': 'accept',
            'inviteId': 'invite-1',
          }),
        ).called(1);
      });

      test('should call manageBandInvite with decline action', () async {
        // Arrange
        when(
          mockFunctions.httpsCallable('manageBandInvite'),
        ).thenReturn(mockCallable);

        // Act
        await repository.respondToInvite(inviteId: 'invite-1', accept: false);

        // Assert
        verify(
          mockCallable.call<dynamic>({
            'action': 'decline',
            'inviteId': 'invite-1',
          }),
        ).called(1);
      });
    });

    group('getIncomingInvites', () {
      test('should stream pending invites for user', () async {
        // Arrange
        await fakeFirestore.collection('invites').doc('invite-1').set({
          'target_uid': 'user-1',
          'status': 'pendente',
          'band_id': 'band-1',
          'created_at': Timestamp.now(),
        });
        await fakeFirestore.collection('invites').doc('invite-2').set({
          'target_uid': 'user-1',
          'status': 'aceito', // Should NOT appear: not pendente
          'band_id': 'band-2',
          'created_at': Timestamp.now(),
        });

        // Act
        final stream = repository.getIncomingInvites('user-1');
        final first = await stream.first;

        // Assert
        expect(first.length, 1);
        expect(first.first['id'], 'invite-1');
        expect(first.first['band_id'], 'band-1');
      });

      test('should return empty list when no pending invites', () async {
        // Act
        final stream = repository.getIncomingInvites('user-1');
        final first = await stream.first;

        // Assert
        expect(first, isEmpty);
      });
    });

    group('getSentInvites', () {
      test('should stream pending invites for band', () async {
        // Arrange
        await fakeFirestore.collection('invites').doc('invite-1').set({
          'band_id': 'band-1',
          'target_uid': 'user-2',
          'status': 'pendente',
          'created_at': Timestamp.now(),
        });

        // Act
        final stream = repository.getSentInvites('band-1');
        final first = await stream.first;

        // Assert
        expect(first.length, 1);
        expect(first.first['target_uid'], 'user-2');
      });
    });

    group('leaveBand', () {
      test('should call leaveBand cloud function', () async {
        // Arrange
        when(mockFunctions.httpsCallable('leaveBand')).thenReturn(mockCallable);

        // Act
        await repository.leaveBand(bandId: 'band-1', uid: 'user-1');

        // Assert
        verify(mockFunctions.httpsCallable('leaveBand')).called(1);
        verify(
          mockCallable.call<dynamic>({'bandId': 'band-1', 'userId': 'user-1'}),
        ).called(1);
      });

      test('should throw exception on error', () async {
        // Arrange
        when(mockFunctions.httpsCallable('leaveBand')).thenReturn(mockCallable);
        when(
          mockCallable.call<dynamic>(any),
        ).thenThrow(Exception('Cloud Function error'));

        // Act & Assert
        expect(
          () => repository.leaveBand(bandId: 'band-1', uid: 'user-1'),
          throwsException,
        );
      });
    });

    group('cancelInvite', () {
      test('should call manageBandInvite with cancel action', () async {
        // Arrange
        when(
          mockFunctions.httpsCallable('manageBandInvite'),
        ).thenReturn(mockCallable);

        // Act
        await repository.cancelInvite('invite-1');

        // Assert
        verify(
          mockCallable.call<dynamic>({
            'action': 'cancel',
            'inviteId': 'invite-1',
          }),
        ).called(1);
      });
    });
  });
}
