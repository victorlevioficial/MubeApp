import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/store_review_service.dart';
import '../../data/gig_repository.dart';
import '../../domain/gig_draft.dart';
import 'gig_session_guard.dart';

part 'create_gig_controller.g.dart';

class CreateGigSubmissionResult {
  const CreateGigSubmissionResult({
    required this.gigId,
    required this.isFirstGigForCurrentUser,
  });

  final String gigId;
  final bool isFirstGigForCurrentUser;
}

@riverpod
class CreateGigController extends _$CreateGigController {
  @override
  FutureOr<void> build() {}

  Future<CreateGigSubmissionResult> submitDraft(GigDraft draft) async {
    state = const AsyncLoading();

    try {
      final gigId = await GigSessionGuard.run(
        ref,
        operationLabel: 'create_gig_submit',
        action: () => ref.read(gigRepositoryProvider).createGig(draft),
      );
      final gigCount = await ref.read(gigRepositoryProvider).getCurrentUserGigCount();
      final isFirstGigForCurrentUser = gigCount == 1;
      if (isFirstGigForCurrentUser) {
        await ref
            .read(storeReviewServiceProvider)
            .recordTrigger(StoreReviewTrigger.firstGigCreated);
      }
      state = const AsyncData(null);
      return CreateGigSubmissionResult(
        gigId: gigId,
        isFirstGigForCurrentUser: isFirstGigForCurrentUser,
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateDraft(String gigId, GigUpdate update) async {
    state = const AsyncLoading();
    try {
      await GigSessionGuard.run(
        ref,
        operationLabel: 'create_gig_update',
        action: () => ref.read(gigRepositoryProvider).updateGig(gigId, update),
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
