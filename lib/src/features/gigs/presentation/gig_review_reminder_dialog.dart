import 'package:flutter/material.dart';

import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../domain/gig_review_opportunity.dart';

class GigReviewReminderDialog extends StatelessWidget {
  const GigReviewReminderDialog({super.key, required this.opportunity});

  final GigReviewOpportunity opportunity;

  static Future<bool?> show(
    BuildContext context, {
    required GigReviewOpportunity opportunity,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => GigReviewReminderDialog(opportunity: opportunity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppConfirmationDialog(
      title: 'Avaliacao pendente',
      message:
          'Voce ainda precisa avaliar ${opportunity.reviewedUserName} '
          'pela gig "${opportunity.gigTitle}".',
      confirmText: 'Avaliar',
      cancelText: 'Agora nao',
      isDestructive: false,
    );
  }
}
