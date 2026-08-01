import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/support/domain/ticket_model.dart';
import 'package:mube/src/features/support/presentation/support_controller.dart';
import 'package:mube/src/features/support/presentation/ticket_detail_screen.dart';

void main() {
  Widget createSubject(Stream<List<Ticket>> Function() streamBuilder) {
    return ProviderScope(
      overrides: [userTicketsProvider.overrideWith((ref) => streamBuilder())],
      child: const MaterialApp(
        home: TicketDetailScreen(ticketId: 'missing-ticket'),
      ),
    );
  }

  testWidgets('shows not found instead of loading forever', (tester) async {
    await tester.pumpWidget(createSubject(() => Stream.value(const [])));
    await tester.pumpAndSettle();

    expect(find.text('Chamado não encontrado'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows retry when ticket loading fails', (tester) async {
    await tester.pumpWidget(
      createSubject(() => Stream.error(Exception('offline'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o chamado'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('accepts a ticket id shorter than eight characters', (
    tester,
  ) async {
    final ticket = Ticket(
      id: 'abc',
      userId: 'user-1',
      title: 'Ajuda',
      description: 'Descrição do chamado',
      category: 'bug',
      status: TicketStatus.open,
      createdAt: DateTime(2026, 7, 28),
      updatedAt: DateTime(2026, 7, 28),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TicketDetailScreen(ticketId: ticket.id, ticketObj: ticket),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('#abc'), findsOneWidget);
    expect(find.text('Ajuda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
