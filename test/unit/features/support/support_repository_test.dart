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

    group('getUserTickets', () {
      test('should return tickets for specific user', () async {
        // Arrange
        await repository.createTicket(tTicket);
        await repository.createTicket(
          Ticket(
            id: 'ticket-2',
            userId: 'user-1',
            title: 'Outro bug',
            description: 'Descrição',
            category: 'feedback',
            status: TicketStatus.open,
            createdAt: DateTime(2025, 1, 2),
            updatedAt: DateTime(2025, 1, 2),
          ),
        );
        // Ticket from another user
        await repository.createTicket(
          Ticket(
            id: 'ticket-3',
            userId: 'user-2',
            title: 'Ticket do outro',
            description: 'Outro',
            category: 'other',
            status: TicketStatus.open,
            createdAt: DateTime(2025, 1, 3),
            updatedAt: DateTime(2025, 1, 3),
          ),
        );

        // Act
        final result = await repository.getUserTickets('user-1');

        // Assert
        expect(result.length, 2);
        expect(result.every((t) => t.userId == 'user-1'), true);
      });

      test('should return empty list when user has no tickets', () async {
        // Act
        final result = await repository.getUserTickets('nonexistent');

        // Assert
        expect(result, isEmpty);
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
