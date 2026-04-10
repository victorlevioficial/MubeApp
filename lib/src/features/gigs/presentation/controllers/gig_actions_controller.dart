import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../routing/route_paths.dart';
import '../../../../utils/app_logger.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../chat/data/chat_repository.dart';
import '../../data/gig_repository.dart';
import '../../domain/application_status.dart';
import '../../domain/gig_draft.dart';
import 'gig_session_guard.dart';

part 'gig_actions_controller.g.dart';

@Riverpod(keepAlive: true)
class GigActionsController extends _$GigActionsController {
  /// Label of the currently executing action, or null if idle.
  /// Use to show per-button loading indicators in UI.
  String? get activeAction => _activeAction;
  String? _activeAction;

  @override
  FutureOr<void> build() {
    _activeAction = null;
  }

  Future<void> applyToGig(String gigId, String message) async {
    await _runGigAction(
      operationLabel: 'gig_apply',
      action: (repository) => repository.applyToGig(gigId, message),
    );
  }

  Future<void> withdrawApplication(String gigId) async {
    await _runGigAction(
      operationLabel: 'gig_withdraw_application',
      action: (repository) => repository.withdrawApplication(gigId),
    );
  }

  Future<void> closeGig(String gigId) async {
    await _runGigAction(
      operationLabel: 'gig_close',
      action: (repository) => repository.closeGig(gigId),
    );
  }

  Future<void> cancelGig(String gigId) async {
    await _runGigAction(
      operationLabel: 'gig_cancel',
      action: (repository) => repository.cancelGig(gigId),
    );
  }

  Future<void> updateGig(String gigId, GigUpdate update) async {
    await _runGigAction(
      operationLabel: 'gig_update',
      action: (repository) => repository.updateGig(gigId, update),
    );
  }

  Future<void> _runGigAction({
    required String operationLabel,
    required Future<void> Function(GigRepository repository) action,
  }) async {
    _activeAction = operationLabel;
    state = const AsyncLoading();

    try {
      await GigSessionGuard.run(
        ref,
        operationLabel: operationLabel,
        action: () => action(ref.read(gigRepositoryProvider)),
      );
      if (!ref.mounted) return;
      _activeAction = null;
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        _activeAction = null;
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> acceptApplication({
    required String gigId,
    required String applicantId,
  }) async {
    await _runGigAction(
      operationLabel: 'gig_accept_application',
      action: (repository) => repository.updateApplicationStatus(
        gigId,
        applicantId,
        ApplicationStatus.accepted,
      ),
    );

    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null || applicantId.isEmpty) return;

    try {
      final reevaluateResult = await ref
          .read(chatRepositoryProvider)
          .reevaluateConversationAccessByUsers(
            userAId: currentUser.uid,
            userBId: applicantId,
            trigger: 'gig_application_accepted',
          );
      reevaluateResult.fold(
        (failure) => AppLogger.warning(
          'Falha ao promover conversa apos aceite de candidatura',
          failure.message,
        ),
        (_) {},
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Promocao de conversa apos aceite de candidatura indisponivel neste contexto',
        '$e\n$stackTrace',
      );
    }
  }

  Future<void> rejectApplication({
    required String gigId,
    required String applicantId,
  }) async {
    await _runGigAction(
      operationLabel: 'gig_reject_application',
      action: (repository) => repository.updateApplicationStatus(
        gigId,
        applicantId,
        ApplicationStatus.rejected,
      ),
    );
  }

  Future<void> openConversation(
    BuildContext context, {
    required String otherUserId,
  }) async {
    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) {
      throw Exception('Usuario nao autenticado.');
    }

    final conversationId = ref
        .read(chatRepositoryProvider)
        .getConversationId(currentUser.uid, otherUserId);
    if (!context.mounted) return;
    await context.push(
      RoutePaths.conversationById(conversationId),
      extra: {'otherUserId': otherUserId, 'conversationType': 'gig'},
    );
  }
}
