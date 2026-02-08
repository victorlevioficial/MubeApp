import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../domain/ticket_model.dart';
import 'support_controller.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  final Ticket? ticketObj;

  const TicketDetailScreen({super.key, required this.ticketId, this.ticketObj});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If ticket object is passed, use it. Otherwise, try to find it in the provider.
    Ticket? ticket = ticketObj;

    if (ticket == null) {
      final ticketsAsync = ref.watch(userTicketsProvider);
      ticket = ticketsAsync.asData?.value.cast<Ticket?>().firstWhere(
        (t) => t?.id == ticketId,
        orElse: () => null,
      );
    }

    if (ticket == null) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Detalhes do Chamado'),
        body: Center(child: AppLoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: '#${ticket.id.substring(0, 8)}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(ticket),
            const SizedBox(height: AppSpacing.s24),
            Text('Descrição', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.s8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.all12,
                border: Border.all(color: AppColors.surfaceHighlight),
              ),
              child: Text(ticket.description, style: AppTypography.bodyMedium),
            ),
            if (ticket.imageUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s24),
              Text('Anexos', style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.s12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ticket.imageUrls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.s12),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _showFullScreenImage(context, ticket!.imageUrls[index]);
                      },
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.all12,
                          border: Border.all(color: AppColors.surfaceHighlight),
                          image: DecorationImage(
                            image: NetworkImage(ticket!.imageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s32),
            _buildStatusTimeline(ticket),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Ticket ticket) {
    final statusColor = _getStatusColor(ticket.status);
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(ticket.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: AppRadius.all16,
                border: Border.all(color: statusColor),
              ),
              child: Text(
                ticket.status.label.toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s4,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: AppRadius.all16,
              ),
              child: Text(
                ticket.category.toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(ticket.title, style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Criado em $dateStr',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(Ticket ticket) {
    // Placeholder for a future timeline or responses section
    // For now, simple text explaining support process
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              'Você receberá atualizações sobre este chamado via e-mail e notificação.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black.withOpacity(0.8),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            InteractiveViewer(child: Image.network(imageUrl)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
