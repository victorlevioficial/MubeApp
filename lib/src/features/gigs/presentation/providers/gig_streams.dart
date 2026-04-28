// ignore_for_file: directives_ordering

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/offline_mutation_queue.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../data/gig_repository.dart';
import '../../domain/application_status.dart';
import '../../domain/gig.dart';
import '../../domain/gig_application.dart';
import '../../domain/gig_review.dart';
import '../../domain/gig_review_opportunity.dart';
import '../../../../utils/app_performance_tracker.dart';
import 'gig_filters_controller.dart';

part 'gig_streams.g.dart';

final gigUsersByStableIdsProvider =
    FutureProvider.family<Map<String, AppUser>, String>((ref, idsKey) {
      final uid = _currentAuthenticatedUid(ref);
      if (uid == null) return Future<Map<String, AppUser>>.value(const {});

      return ref
          .read(gigRepositoryProvider)
          .getUsersByIds(_decodeGigUserIdsKey(idsKey));
    });

final myGigApplicationRemoteProvider = StreamProvider.autoDispose
    .family<GigApplication?, String>((ref, gigId) {
      return ref.read(gigRepositoryProvider).watchMyApplicationForGig(gigId);
    });

final myGigApplicationProvider = Provider.autoDispose
    .family<AsyncValue<GigApplication?>, String>((ref, gigId) {
      final remoteApplicationAsync = ref.watch(
        myGigApplicationRemoteProvider(gigId),
      );
      final queuedApplication = _queuedGigApplicationFor(ref, gigId);
      return remoteApplicationAsync.whenData(
        (application) => application ?? queuedApplication,
      );
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

  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) {
    finish('skipped_unauthenticated', items: 0);
    return Stream.value(const <Gig>[]);
  }

  final source = ref.read(gigRepositoryProvider).watchLatestOpenGigs(limit: 3);
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
      final uid = _currentAuthenticatedUid(ref);
      if (uid == null) return Stream.value(const <Gig>[]);

      return ref
          .read(gigRepositoryProvider)
          .watchPublicOpenGigsByCreator(creatorId, limit: 3);
    });

@riverpod
Stream<List<Gig>> gigsStream(Ref ref) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Stream.value(const <Gig>[]);

  final filters = ref.watch(gigFiltersControllerProvider);
  return ref.watch(gigRepositoryProvider).watchGigs(filters);
}

@Riverpod(keepAlive: true)
Stream<List<Gig>> myGigsStream(Ref ref) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Stream.value(const <Gig>[]);

  return ref.watch(gigRepositoryProvider).watchMyGigs();
}

@riverpod
Stream<Gig?> gigDetail(Ref ref, String gigId) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Stream.value(null);

  return ref.watch(gigRepositoryProvider).watchGigById(gigId);
}

@riverpod
Stream<List<GigApplication>> gigApplications(Ref ref, String gigId) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Stream.value(const <GigApplication>[]);

  return ref.watch(gigRepositoryProvider).watchApplications(gigId);
}

@Riverpod(keepAlive: true)
Stream<List<GigApplication>> myApplications(Ref ref) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Stream.value(const <GigApplication>[]);

  final queuedApplications = _queuedGigApplicationsFor(ref, uid);

  return ref
      .read(gigRepositoryProvider)
      .watchMyApplications()
      .map(
        (applications) => _mergeQueuedApplications(
          applications,
          queuedApplications,
          applicantId: uid,
        ),
      );
}

@riverpod
Future<bool> hasApplied(Ref ref, String gigId) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Future<bool>.value(false);

  if (_queuedGigApplicationFor(ref, gigId) != null) {
    return Future<bool>.value(true);
  }
  return ref.watch(gigRepositoryProvider).hasApplied(gigId);
}

@riverpod
Stream<List<GigReview>> userReviews(Ref ref, String userId) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Stream.value(const <GigReview>[]);

  return ref.watch(gigRepositoryProvider).watchReviewsForUser(userId);
}

@riverpod
Future<double?> userAverageRating(Ref ref, String userId) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Future<double?>.value(null);

  return ref.watch(gigRepositoryProvider).getAverageRating(userId);
}

@riverpod
Future<Map<String, AppUser>> gigUsersByIds(Ref ref, List<String> ids) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Future<Map<String, AppUser>>.value(const {});

  return ref.watch(gigRepositoryProvider).getUsersByIds(ids);
}

@riverpod
Future<List<GigReviewOpportunity>> pendingGigReviews(Ref ref) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null) return Future<List<GigReviewOpportunity>>.value(const []);

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

GigApplication? _queuedGigApplicationFor(Ref ref, String gigId) {
  final uid = _currentAuthenticatedUid(ref);
  if (uid == null || uid.isEmpty) {
    return null;
  }

  final entries = ref.watch(offlineMutationStoreProvider);
  final scopeKey = gigApplyMutationScopeKey(gigId.trim());
  OfflineMutation? entry;
  for (final candidate in entries) {
    if (candidate.scopeKey == scopeKey &&
        candidate.type == OfflineMutationType.gigApply) {
      entry = candidate;
      break;
    }
  }
  if (entry == null) {
    return null;
  }

  return _offlineMutationToGigApplication(entry, applicantId: uid);
}

List<GigApplication> _queuedGigApplicationsFor(Ref ref, String applicantId) {
  final entries = ref
      .watch(offlineMutationStoreProvider)
      .where((entry) => entry.type == OfflineMutationType.gigApply);
  return entries
      .map(
        (entry) =>
            _offlineMutationToGigApplication(entry, applicantId: applicantId),
      )
      .whereType<GigApplication>()
      .toList(growable: false);
}

GigApplication? _offlineMutationToGigApplication(
  OfflineMutation entry, {
  required String applicantId,
}) {
  final gigId = entry.gigId?.trim() ?? '';
  final message = entry.gigMessage?.trim() ?? '';
  if (gigId.isEmpty || message.isEmpty) {
    return null;
  }

  return GigApplication(
    id: 'queued:$gigId',
    gigId: gigId,
    applicantId: applicantId,
    message: message,
    status: ApplicationStatus.pending,
    appliedAt: entry.updatedAt,
    gigTitle: entry.gigTitle,
  );
}

String? _currentAuthenticatedUid(Ref ref) {
  return ref.watch(currentUserIdProvider) ??
      ref.read(authRepositoryProvider).currentUser?.uid;
}

List<GigApplication> _mergeQueuedApplications(
  List<GigApplication> remoteApplications,
  List<GigApplication> queuedApplications, {
  required String applicantId,
}) {
  final applicationsByGigId = <String, GigApplication>{
    for (final application in queuedApplications)
      if (application.applicantId == applicantId)
        application.gigId: application,
  };

  for (final application in remoteApplications) {
    applicationsByGigId[application.gigId] = application;
  }

  final mergedApplications = applicationsByGigId.values.toList(growable: false)
    ..sort((a, b) {
      final left = a.appliedAt?.millisecondsSinceEpoch ?? 0;
      final right = b.appliedAt?.millisecondsSinceEpoch ?? 0;
      return right.compareTo(left);
    });

  return mergedApplications;
}
