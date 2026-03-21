// ignore_for_file: directives_ordering

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../data/gig_repository.dart';
import '../../domain/gig.dart';
import '../../domain/gig_application.dart';
import '../../domain/gig_review.dart';
import '../../domain/gig_review_opportunity.dart';
import '../../../../utils/app_performance_tracker.dart';
import 'gig_filters_controller.dart';

part 'gig_streams.g.dart';

final gigUsersByStableIdsProvider =
    FutureProvider.family<Map<String, AppUser>, String>((ref, idsKey) {
      return ref
          .watch(gigRepositoryProvider)
          .getUsersByIds(_decodeGigUserIdsKey(idsKey));
    });

final myGigApplicationProvider = StreamProvider.autoDispose
    .family<GigApplication?, String>((ref, gigId) {
      return ref.watch(gigRepositoryProvider).watchMyApplicationForGig(gigId);
    });

final homeGigsPreviewProvider = StreamProvider.autoDispose<List<Gig>>((ref) {
  final stopwatch = AppPerformanceTracker.startSpan(
    'gigs.home_preview_stream',
    data: {'limit': 3},
  );
  var completed = false;

  void finish(
    String status, {
    int? items,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (completed) return;
    completed = true;
    final payload = <String, Object?>{'status': status};
    if (items != null) {
      payload['items'] = items;
    }
    if (error != null) {
      payload['error_type'] = error.runtimeType.toString();
    }
    AppPerformanceTracker.finishSpan(
      'gigs.home_preview_stream',
      stopwatch,
      data: payload,
    );
  }

  ref.onDispose(() {
    if (!completed) {
      finish('disposed_before_first_event');
    }
  });

  final source = ref.watch(gigRepositoryProvider).watchLatestOpenGigs(limit: 3);
  return source.transform(
    StreamTransformer.fromHandlers(
      handleData: (gigs, sink) {
        finish('first_snapshot', items: gigs.length);
        sink.add(gigs);
      },
      handleError: (error, stackTrace, sink) {
        finish('first_error', error: error, stackTrace: stackTrace);
        sink.addError(error, stackTrace);
      },
    ),
  );
});

final publicCreatorOpenGigsProvider = StreamProvider.autoDispose
    .family<List<Gig>, String>((ref, creatorId) {
      return ref
          .watch(gigRepositoryProvider)
          .watchPublicOpenGigsByCreator(creatorId, limit: 3);
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
  final authAsync = ref.watch(authStateChangesProvider);
  final fallbackUser = ref.read(authRepositoryProvider).currentUser;
  final currentUser = authAsync.asData?.value ?? fallbackUser;

  if (currentUser == null) {
    if (authAsync.hasError) {
      return Stream.error(authAsync.error!, authAsync.stackTrace);
    }
    if (authAsync.isLoading) {
      return const Stream.empty();
    }
    return Stream.value(const <GigApplication>[]);
  }

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
