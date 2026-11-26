import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/support/data/support_repository.dart';
import 'package:mube/src/features/support/domain/ticket_model.dart';

void main() {
  late SupportRepository repository;
  late FakeFirebaseFirestore fakeFirestore;

  final tTicket = Ticket(
    id: 'ticket-1',
    userId: 'user-1',
    title: 'Bug no app',
    description: 'Não consigo salvar meu perfil',
    category: 'bug',
    status: TicketStatus.open,
    imageUrls: const [],
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = SupportRepository(fakeFirestore);
  });

  group('SupportRepository', () {
    group('createTicket', () {
      test('should create ticket document in Firestore', () async {
        // Act
        await repository.createTicket(tTicket);

        // Assert
        final doc = await fakeFirestore
            .collection('tickets')
            .doc(tTicket.id)
            .get();
        expect(doc.exists, true);
        expect(doc.data()?['title'], 'Bug no app');
        expect(doc.data()?['userId'], 'user-1');
        expect(doc.data()?['category'], 'bug');
        expect(doc.data()?['status'], 'open');
      });

      test('should overwrite existing ticket with same id', () async {
        // Arrange
        await repository.createTicket(tTicket);

        final updatedTicket = Ticket(
          id: tTicket.id,
          userId: tTicket.userId,
          title: 'Bug atualizado',
          description: tTicket.description,
          category: tTicket.category,
          status: TicketStatus.inProgress,
          createdAt: tTicket.createdAt,
          updatedAt: DateTime(2025, 1, 2),
        );

        // Act
        await repository.createTicket(updatedTicket);

        // Assert
        final doc = await fakeFirestore
            .collection('tickets')
            .doc(tTicket.id)
            .get();
        expect(doc.data()?['title'], 'Bug atualizado');
        expect(doc.data()?['status'], 'in_progress');
      });
    });

    group('watchUserTickets', () {
      test('should emit ticket list for user', () async {
        // Arrange
        await repository.createTicket(tTicket);

        // Act & Assert
        final stream = repository.watchUserTickets('user-1');
        final firstEmission = await stream.first;

        expect(firstEmission.length, 1);
        expect(firstEmission.first.id, 'ticket-1');
        expect(firstEmission.first.title, 'Bug no app');
      });

      test('should emit empty list when user has no tickets', () async {
        // Act & Assert
        final stream = repository.watchUserTickets('nonexistent');
        final firstEmission = await stream.first;

        expect(firstEmission, isEmpty);
      });
    });
  });
}
