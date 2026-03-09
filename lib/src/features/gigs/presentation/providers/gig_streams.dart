import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/domain/app_user.dart';
import '../../data/gig_repository.dart';
import '../../domain/gig.dart';
import '../../domain/gig_application.dart';
import '../../domain/gig_review.dart';
import '../../domain/gig_review_opportunity.dart';
import 'gig_filters_controller.dart';

part 'gig_streams.g.dart';

final gigUsersByStableIdsProvider = FutureProvider.autoDispose
    .family<Map<String, AppUser>, String>((ref, idsKey) {
      return ref
          .watch(gigRepositoryProvider)
          .getUsersByIds(_decodeGigUserIdsKey(idsKey));
    });

final homeGigsPreviewProvider = StreamProvider.autoDispose<List<Gig>>((ref) {
  return ref.watch(gigRepositoryProvider).watchLatestOpenGigs(limit: 3);
});

@riverpod
Stream<List<Gig>> gigsStream(Ref ref) {
  final filters = ref.watch(gigFiltersControllerProvider);
  return ref.watch(gigRepositoryProvider).watchGigs(filters);
}

@riverpod
Stream<List<Gig>> myGigsStream(Ref ref) {
  return ref.watch(gigRepositoryProvider).watchMyGigs();
}

@riverpod
Stream<Gig?> gigDetail(Ref ref, String gigId) {
  return ref.watch(gigRepositoryProvider).watchGigById(gigId);
}

@riverpod
Stream<List<GigApplication>> gigApplications(Ref ref, String gigId) {
  return ref.watch(gigRepositoryProvider).watchApplications(gigId);
}

@riverpod
Stream<List<GigApplication>> myApplications(Ref ref) {
  return ref.watch(gigRepositoryProvider).watchMyApplications();
}

@riverpod
Future<bool> hasApplied(Ref ref, String gigId) {
  return ref.watch(gigRepositoryProvider).hasApplied(gigId);
}

@riverpod
Stream<List<GigReview>> userReviews(Ref ref, String userId) {
  return ref.watch(gigRepositoryProvider).watchReviewsForUser(userId);
}

@riverpod
Future<double?> userAverageRating(Ref ref, String userId) {
  return ref.watch(gigRepositoryProvider).getAverageRating(userId);
}

@riverpod
Future<Map<String, AppUser>> gigUsersByIds(Ref ref, List<String> ids) {
  return ref.watch(gigRepositoryProvider).getUsersByIds(ids);
}

@riverpod
Future<List<GigReviewOpportunity>> pendingGigReviews(Ref ref) {
  return ref.watch(gigRepositoryProvider).getPendingReviewsForCurrentUser();
}

String encodeGigUserIdsKey(Iterable<String> ids) {
  final normalizedIds =
      ids
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort();
  return normalizedIds.join('|');
}

List<String> _decodeGigUserIdsKey(String idsKey) {
  if (idsKey.trim().isEmpty) return const [];
  return idsKey
      .split('|')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
}
