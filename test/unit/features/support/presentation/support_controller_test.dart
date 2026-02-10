import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/storage/data/storage_repository.dart';
import 'package:mube/src/features/support/data/support_repository.dart';
import 'package:mube/src/features/support/presentation/support_controller.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeSupportRepository fakeSupportRepository;
  late FakeStorageRepository fakeStorageRepository;
  late ProviderContainer container;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeSupportRepository = FakeSupportRepository();
    fakeStorageRepository = FakeStorageRepository();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        supportRepositoryProvider.overrideWithValue(fakeSupportRepository),
        storageRepositoryProvider.overrideWithValue(fakeStorageRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SupportController', () {
    test('initial state is AsyncData(null)', () {
      final controller = container.read(supportControllerProvider);
      expect(controller, const AsyncData<void>(null));
    });

    group('submitTicket', () {
      test('submits ticket successfully without attachments', () async {
        // Setup user
        final user = TestData.user(uid: 'user-1');
        final firebaseUser = FakeFirebaseUser(
          uid: 'user-1',
          email: 'test@test.com',
        );
        fakeAuthRepository.emitUser(firebaseUser);
        fakeAuthRepository.appUser = user;

        // Wait for auth providers to initialize
        await waitForUser(container);

        final controller = container.read(supportControllerProvider.notifier);

        await controller.submitTicket(
          title: 'Help me',
          description: 'I need help',
          category: 'technical',
        );

        // Verify ticket created
        expect(fakeSupportRepository.tickets.length, 1);
        final ticket = fakeSupportRepository.tickets.first;
        expect(ticket.title, 'Help me');
        expect(ticket.description, 'I need help');
        expect(ticket.category, 'technical');
        expect(ticket.userId, 'user-1');
        expect(ticket.imageUrls, isEmpty);

        // Verify state success
        expect(
          container.read(supportControllerProvider),
          const AsyncData<void>(null),
        );
      });

      test('submits ticket successfully with attachments', () async {
        final user = TestData.user(uid: 'user-1');
        fakeAuthRepository.emitUser(
          FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        );
        fakeAuthRepository.appUser = user;
        fakeAuthRepository.appUser = user;
        await waitForUser(container);

        final controller = container.read(supportControllerProvider.notifier);
        final file = File('path/to/file.jpg');

        await controller.submitTicket(
          title: 'Bug with image',
          description: 'See attachment',
          category: 'bug',
          attachments: [file],
        );

        expect(fakeSupportRepository.tickets.length, 1);
        final ticket = fakeSupportRepository.tickets.first;
        expect(ticket.imageUrls, ['http://fake.url/image.jpg']);
      });

      test('sets state to AsyncError when user is not logged in', () async {
        fakeAuthRepository.emitUser(null);
        fakeAuthRepository.appUser = null;

        // Ensure provider updates to null
        // Note: currentUserProfileProvider relies on authStateChanges
        // We verify that the controller handles the null user check

        final controller = container.read(supportControllerProvider.notifier);

        await controller.submitTicket(
          title: 'Fail',
          description: 'No user',
          category: 'general',
        );

        expect(container.read(supportControllerProvider), isA<AsyncError>());
      });

      test('sets state to AsyncError on storage upload failure', () async {
        final user = TestData.user(uid: 'user-1');
        fakeAuthRepository.emitUser(
          FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        );
        fakeAuthRepository.appUser = user;
        fakeAuthRepository.appUser = user;
        await waitForUser(container);

        fakeStorageRepository.throwError = true;

        final controller = container.read(supportControllerProvider.notifier);
        final file = File('path/to/file.jpg');

        await controller.submitTicket(
          title: 'Upload Fail',
          description: '...',
          category: 'bug',
          attachments: [file],
        );

        expect(container.read(supportControllerProvider), isA<AsyncError>());
        // Verify no ticket created
        expect(fakeSupportRepository.tickets.isEmpty, true);
      });

      test('sets state to AsyncError on ticket creation failure', () async {
        final user = TestData.user(uid: 'user-1');
        fakeAuthRepository.emitUser(
          FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        );
        fakeAuthRepository.appUser = user;
        await waitForUser(container);

        fakeSupportRepository.throwError = true;

        final controller = container.read(supportControllerProvider.notifier);

        await controller.submitTicket(
          title: 'Db Fail',
          description: '...',
          category: 'bug',
        );

        expect(container.read(supportControllerProvider), isA<AsyncError>());
      });
    });
  });
}

Future<void> waitForUser(ProviderContainer container) async {
  final completer = Completer<void>();
  final sub = container.listen(currentUserProfileProvider, (previous, next) {
    if (next.hasValue && next.value != null) {
      if (!completer.isCompleted) completer.complete();
    }
  }, fireImmediately: true);
  await completer.future.timeout(const Duration(seconds: 1));
  sub.close();
}
