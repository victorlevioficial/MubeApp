import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_chip.dart';
import '../../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../../design_system/components/feedback/app_overlay.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/application_status.dart';
import '../../domain/gig.dart';
import '../../domain/gig_application.dart';
import '../../domain/gig_date_mode.dart';
import '../../domain/gig_draft.dart';
import '../../domain/gig_location_type.dart';
import '../../domain/gig_status.dart';
import '../controllers/gig_actions_controller.dart';
import '../gig_error_message.dart';
import '../providers/gig_streams.dart';
import '../widgets/gig_compensation_chip.dart';
import '../widgets/gig_creator_preview.dart';
import '../widgets/gig_status_badge.dart';
import '../widgets/gig_visuals.dart';

part 'gig_detail_screen_actions.dart';
part 'gig_detail_screen_ui.dart';
part 'gig_detail_screen_widgets.dart';

enum _GigDetailPendingAction {
  apply,
  withdraw,
  closeGig,
  cancelGig,
  updateDescription,
}

class GigDetailScreen extends ConsumerStatefulWidget {
  const GigDetailScreen({super.key, required this.gigId});

  final String gigId;

  @override
  ConsumerState<GigDetailScreen> createState() => _GigDetailScreenState();
}

class _GigDetailScreenState extends ConsumerState<GigDetailScreen> {
  _GigDetailPendingAction? _pendingAction;

  @override
  Widget build(BuildContext context) => _buildGigDetailScreen(context);

  Future<void> _runPendingAction(
    _GigDetailPendingAction action,
    Future<void> Function() operation,
  ) async {
    if (_pendingAction != null) return;

    setState(() => _pendingAction = action);
    try {
      await operation();
    } finally {
      if (mounted) {
        setState(() => _pendingAction = null);
      }
    }
  }
}
