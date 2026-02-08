import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../routing/route_paths.dart';

import '../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
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
                  const SizedBox(height: AppSpacing.s16),
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
            padding: AppSpacing.all16,
            itemCount: tickets.length,
            separatorBuilder: (_, index) =>
                const SizedBox(height: AppSpacing.s12),
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
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            final path =
                '${RoutePaths.support}/${RoutePaths.supportTickets}/${RoutePaths.supportTicketDetail}'
                    .replaceAll(':ticketId', ticket.id);
            context.go(path, extra: ticket);
          },
          borderRadius: AppRadius.all12,
          child: Padding(
            padding: AppSpacing.all16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          ticket.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: AppRadius.all8,
                        border: Border.all(
                          color: _getStatusColor(ticket.status),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        ticket.status.label.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: _getStatusColor(ticket.status),
                          fontWeight: AppTypography.buttonPrimary.fontWeight,
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
                const SizedBox(height: AppSpacing.s12),
                Text(
                  ticket.title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: AppTypography.titleSmall.fontWeight,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
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
