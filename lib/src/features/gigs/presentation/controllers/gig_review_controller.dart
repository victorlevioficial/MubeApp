import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/gig_repository.dart';
import '../../domain/gig_draft.dart';
import 'gig_session_guard.dart';

part 'gig_review_controller.g.dart';

@riverpod
class GigReviewController extends _$GigReviewController {
  @override
  FutureOr<void> build() {}

  Future<void> submitReview(GigReviewDraft review) async {
    state = const AsyncLoading();
    try {
      await GigSessionGuard.run(
        ref,
        operationLabel: 'gig_submit_review',
        action: () => ref.read(gigRepositoryProvider).submitReview(review),
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
