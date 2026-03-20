import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'core/providers/app_display_preferences_provider.dart';
import 'core/providers/app_update_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/push_notification_event_bus.dart';
import 'core/services/push_notification_provider.dart';
import 'core/services/session_prompt_coordinator.dart';
import 'core/services/store_review_service.dart';
import 'core/widgets/app_update_notice_dialog.dart';
import 'design_system/components/feedback/app_snackbar.dart';
import 'design_system/foundations/theme/app_scroll_behavior.dart';
import 'design_system/foundations/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/domain/user_type.dart';
import 'features/auth/presentation/account_deletion_provider.dart';
import 'features/bands/domain/band_activation_rules.dart';
import 'features/bands/presentation/band_formation_reminder_dialog.dart';
import 'features/gigs/domain/gig_review_opportunity.dart';
import 'features/gigs/presentation/gig_review_reminder_dialog.dart';
import 'features/gigs/presentation/providers/gig_streams.dart';
import 'features/onboarding/presentation/onboarding_form_provider.dart';
import 'routing/app_router.dart';
import 'routing/route_paths.dart';
import 'shared/widgets/dismiss_keyboard_on_tap.dart';
import 'utils/app_logger.dart';
import 'utils/app_performance_tracker.dart';

part 'app/app_push_navigation.dart';
part 'app/app_prompt_dispatch.dart';
part 'app/app_prompt_guards.dart';
part 'app/app_update_notice_prompt.dart';
part 'app/app_band_reminder_prompt.dart';
part 'app/app_gig_review_prompt.dart';
part 'app/app_store_review_prompt.dart';
part 'app/app_session_effects.dart';
part 'app/mube_app_view.dart';

/// Global key for ScaffoldMessenger to show snackbars across navigation.
/// This allows snackbars to persist even when navigating between screens.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MubeApp extends ConsumerStatefulWidget {
  final VoidCallback? onInitialRouteReady;

  const MubeApp({super.key, this.onInitialRouteReady});

  @override
  ConsumerState<MubeApp> createState() => _MubeAppState();
}

class _MubeAppState extends ConsumerState<MubeApp> {
  StreamSubscription? _onMessageOpenedSub;
  ProviderSubscription<AsyncValue<User?>>? _authStateSubscription;
  ProviderSubscription<AsyncValue<AppUser?>>? _profileSubscription;
  late final GoRouter _goRouter;
  PushNavigationIntent? _pendingPushNavigationIntent;
  bool _hasBootstrappedPushForSession = false;
  bool _hasPrefetchedFeedForSession = false;
  bool _hasReleasedInitialRoute = false;
  bool _isPushNavigationDispatchScheduled = false;
  bool _isStoreReviewEvaluationInProgress = false;
  String? _onboardingDraftOwnerUid;
  String? _storeReviewSessionOwnerUid;
  Timer? _pushBootstrapTimer;
  final SessionPromptCoordinator _appUpdateNoticeCoordinator =
      SessionPromptCoordinator(pendingInitially: true);
  final UserScopedSessionPromptCoordinator _bandMembersReminderCoordinator =
      UserScopedSessionPromptCoordinator(logLabel: 'BandFormationReminder');
  final UserScopedSessionPromptCoordinator _gigReviewReminderCoordinator =
      UserScopedSessionPromptCoordinator(logLabel: 'GigReviewReminder');

  @override
  void initState() {
    super.initState();
    _goRouter = ref.read(goRouterProvider);
    _MubeAppSessionEffects(this)._initializeSessionEffects();
  }

  @override
  void dispose() {
    unawaited(_onMessageOpenedSub?.cancel());
    _onMessageOpenedSub = null;
    _MubeAppSessionEffects(this)._disposeSessionEffects();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MubeAppView(this)._buildAppView(context);
  }
}
