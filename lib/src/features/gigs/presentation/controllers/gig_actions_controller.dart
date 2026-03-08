import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../routing/route_paths.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../chat/data/chat_repository.dart';
import '../../data/gig_repository.dart';
import '../../domain/application_status.dart';
import '../../domain/gig_draft.dart';

part 'gig_actions_controller.g.dart';

@riverpod
class GigActionsController extends _$GigActionsController {
  @override
  FutureOr<void> build() {}

  Future<void> applyToGig(String gigId, String message) async {
    state = const AsyncLoading();
    try {
      await ref.read(gigRepositoryProvider).applyToGig(gigId, message);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> withdrawApplication(String gigId) async {
    state = const AsyncLoading();
    try {
      await ref.read(gigRepositoryProvider).withdrawApplication(gigId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> closeGig(String gigId) async {
    state = const AsyncLoading();
    try {
      await ref.read(gigRepositoryProvider).closeGig(gigId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelGig(String gigId) async {
    state = const AsyncLoading();
    try {
      await ref.read(gigRepositoryProvider).cancelGig(gigId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateGig(String gigId, GigUpdate update) async {
    state = const AsyncLoading();
    try {
      await ref.read(gigRepositoryProvider).updateGig(gigId, update);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> acceptApplication({
    required String gigId,
    required String applicantId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(gigRepositoryProvider)
          .updateApplicationStatus(
            gigId,
            applicantId,
            ApplicationStatus.accepted,
          );
      await _ensureConversationExists(applicantId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> rejectApplication({
    required String gigId,
    required String applicantId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(gigRepositoryProvider)
          .updateApplicationStatus(
            gigId,
            applicantId,
            ApplicationStatus.rejected,
          );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
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
    await context.push(RoutePaths.conversationById(conversationId));
  }

  Future<void> _ensureConversationExists(String otherUserId) async {
    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) return;

    final users = await ref.read(gigRepositoryProvider).getUsersByIds([otherUserId]);
    final otherUser = users[otherUserId];
    if (otherUser == null) return;

    final result = await ref
        .read(chatRepositoryProvider)
        .getOrCreateConversation(
          myUid: currentUser.uid,
          otherUid: otherUser.uid,
          otherUserName: otherUser.appDisplayName,
          otherUserPhoto: otherUser.foto,
          myName: currentUser.appDisplayName,
          myPhoto: currentUser.foto,
          type: 'gig',
        );

    result.fold((_) => null, (_) => null);
  }
}
