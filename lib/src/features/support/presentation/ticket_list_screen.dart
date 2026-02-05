import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../domain/ticket_model.dart';
import 'support_controller.dart';

class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(userTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Meus Chamados'),
      body: ticketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum chamado aberto',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _TicketCard(ticket: ticket);
            },
          );
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  const _TicketCard({required this.ticket});

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return AppColors.info;
      case TicketStatus.inProgress:
        return AppColors.warning;
      case TicketStatus.resolved:
        return AppColors.success;
      case TicketStatus.closed:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(ticket.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navegação para detalhes será implementada na v2
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          ticket.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(ticket.status),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        ticket.status.label.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: _getStatusColor(ticket.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ticket.title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
