import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/gig_repository.dart';
import '../../domain/gig_draft.dart';

part 'create_gig_controller.g.dart';

@riverpod
class CreateGigController extends _$CreateGigController {
  @override
  FutureOr<void> build() {}

  Future<String> submitDraft(GigDraft draft) async {
    state = const AsyncLoading();
    final repository = ref.read(gigRepositoryProvider);

    try {
      final gigId = await repository.createGig(draft);
      state = const AsyncData(null);
      return gigId;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateDraft(String gigId, GigUpdate update) async {
    state = const AsyncLoading();
    try {
      await ref.read(gigRepositoryProvider).updateGig(gigId, update);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
