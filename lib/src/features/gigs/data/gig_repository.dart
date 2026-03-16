import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../utils/app_logger.dart';
import '../../auth/domain/app_user.dart';
import '../domain/application_status.dart';
import '../domain/compensation_type.dart';
import '../domain/gig.dart';
import '../domain/gig_application.dart';
import '../domain/gig_date_mode.dart';
import '../domain/gig_draft.dart';
import '../domain/gig_filters.dart';
import '../domain/gig_location_type.dart';
import '../domain/gig_review.dart';
import '../domain/gig_review_opportunity.dart';
import '../domain/gig_status.dart';
import '../domain/gig_type.dart';
import '../domain/review_type.dart';

part 'gig_repository.g.dart';

@Riverpod(keepAlive: true)
GigRepository gigRepository(Ref ref) {
  return GigRepository(
    ref.read(firebaseFirestoreProvider),
    ref.read(firebaseAuthProvider),
  );
}

class GigRepository {
  GigRepository(this._firestore, this._auth);

  static const int _maxFirestoreRetryAttempts = 3;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _gigs =>
      _firestore.collection(FirestoreCollections.gigs);

  CollectionReference<Map<String, dynamic>> _applications(String gigId) =>
      _gigs.doc(gigId).collection(FirestoreCollections.gigApplications);

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FirestoreCollections.gigReviews);

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario nao autenticado');
    return user.uid;
  }

  bool _isTransientFirestoreError(FirebaseException error) {
    final code = error.code.toLowerCase();
    return code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        code == 'aborted';
  }

  Duration _retryDelayForAttempt(int attempt) {
    return Duration(milliseconds: 350 * attempt);
  }

  Exception _wrapFirestoreException(FirebaseException error) {
    return Exception(mapExceptionToFailure(error).message);
  }

  bool _isSecurityContextFailure(FirebaseException error) {
    final code = error.code.toLowerCase();
    return code == 'permission-denied' ||
        code == 'unauthenticated' ||
        code == 'failed-precondition';
  }

  Future<T> _runFirestoreRequest<T>(
    Future<T> Function() request, {
    required String operationLabel,
  }) async {
    for (var attempt = 1; attempt <= _maxFirestoreRetryAttempts; attempt++) {
      try {
        return await request();
      } on FirebaseException catch (error, stackTrace) {
        final shouldRetry =
            _isTransientFirestoreError(error) &&
            attempt < _maxFirestoreRetryAttempts;
        if (!shouldRetry) {
          AppLogger.error(
            'GigRepository Firestore request failed: $operationLabel',
            error,
            stackTrace,
          );
          throw _wrapFirestoreException(error);
        }

        final delay = _retryDelayForAttempt(attempt);
        AppLogger.warning(
          'GigRepository Firestore request transient failure on '
          '$operationLabel (${error.code}). Retrying in '
          '${delay.inMilliseconds}ms.',
          error,
          stackTrace,
          false,
        );
        await Future<void>.delayed(delay);
      }
    }

    throw Exception('Nao foi possivel concluir a operacao agora.');
  }

  Stream<T> _streamWithFirestoreRetry<T>(
    Stream<T> Function() createStream, {
    required String operationLabel,
  }) async* {
    var attempt = 0;

    while (true) {
      try {
        await for (final value in createStream()) {
          yield value;
        }
        return;
      } on FirebaseException catch (error, stackTrace) {
        final shouldRetry =
            _isTransientFirestoreError(error) &&
            attempt < (_maxFirestoreRetryAttempts - 1);
        if (!shouldRetry) {
          AppLogger.error(
            'GigRepository Firestore stream failed: $operationLabel',
            error,
            stackTrace,
          );
          throw _wrapFirestoreException(error);
        }

        attempt += 1;
        final delay = _retryDelayForAttempt(attempt);
        AppLogger.warning(
          'GigRepository Firestore stream transient failure on '
          '$operationLabel (${error.code}). Retrying in '
          '${delay.inMilliseconds}ms.',
          error,
          stackTrace,
          false,
        );
        await Future<void>.delayed(delay);
      }
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getDocument(
    DocumentReference<Map<String, dynamic>> reference, {
    required String operationLabel,
  }) {
    return _runFirestoreRequest(
      () => reference.get(),
      operationLabel: operationLabel,
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getQuerySnapshot(
    Query<Map<String, dynamic>> query, {
    required String operationLabel,
  }) {
    return _runFirestoreRequest(
      () => query.get(),
      operationLabel: operationLabel,
    );
  }

  Future<AggregateQuerySnapshot> _getAggregateSnapshot(
    AggregateQuery query, {
    required String operationLabel,
  }) {
    return _runFirestoreRequest(
      () => query.get(),
      operationLabel: operationLabel,
    );
  }

  Future<void> _setDocument(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data, {
    SetOptions? options,
    required String operationLabel,
  }) {
    return _runFirestoreRequest(
      () => reference.set(data, options),
      operationLabel: operationLabel,
    );
  }

  Future<void> _updateDocument(
    DocumentReference<Map<String, dynamic>> reference,
    Map<Object, Object?> data, {
    required String operationLabel,
  }) {
    return _runFirestoreRequest(
      () => reference.update(data),
      operationLabel: operationLabel,
    );
  }

  Future<void> _deleteDocument(
    DocumentReference<Map<String, dynamic>> reference, {
    required String operationLabel,
  }) {
    return _runFirestoreRequest(
      () => reference.delete(),
      operationLabel: operationLabel,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchQuery(
    Query<Map<String, dynamic>> query, {
    required String operationLabel,
  }) {
    return _streamWithFirestoreRetry(
      () => query.snapshots(),
      operationLabel: operationLabel,
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _watchDocument(
    DocumentReference<Map<String, dynamic>> reference, {
    required String operationLabel,
  }) {
    return _streamWithFirestoreRetry(
      () => reference.snapshots(),
      operationLabel: operationLabel,
    );
  }

  Future<AppUser?> _loadCurrentProfile() async {
    final uid = _uid;
    final doc = await _getDocument(
      _firestore.collection(FirestoreCollections.users).doc(uid),
      operationLabel: 'load_current_profile',
    );
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromJson(doc.data()!);
  }

  Future<void> _ensureCanInteract() async {
    final profile = await _loadCurrentProfile();
    if (profile == null || !profile.isCadastroConcluido) {
      throw Exception('Finalize seu cadastro para usar gigs.');
    }
  }

  Stream<List<Gig>> watchGigs(GigFilters filters) {
    var query = _gigs.orderBy(GigFields.createdAt, descending: true);

    final statuses = filters.statuses;
    if (statuses.length == 1) {
      query = query.where(
        GigFields.status,
        isEqualTo: _gigStatusValue(statuses.first),
      );
    } else if (statuses.length > 1) {
      query = query.where(
        GigFields.status,
        whereIn: statuses.map(_gigStatusValue).toList(),
      );
    }

    if (filters.gigTypes.length == 1) {
      query = query.where(
        GigFields.gigType,
        isEqualTo: _gigTypeValue(filters.gigTypes.first),
      );
    } else if (filters.gigTypes.length > 1 && filters.gigTypes.length <= 10) {
      query = query.where(
        GigFields.gigType,
        whereIn: filters.gigTypes.map(_gigTypeValue).toList(),
      );
    }

    if (filters.onlyMine) {
      query = query.where(GigFields.creatorId, isEqualTo: _uid);
    }

    return _watchQuery(query, operationLabel: 'watch_gigs').map((snapshot) {
      final gigs = snapshot.docs.map(Gig.fromFirestore).toList(growable: false);
      return gigs
          .where((gig) => _matchesFilters(gig, filters))
          .toList(growable: false);
    });
  }

  Stream<List<Gig>> watchLatestOpenGigs({int limit = 3}) {
    final query = _gigs
        .where(GigFields.status, isEqualTo: _gigStatusValue(GigStatus.open))
        .orderBy(GigFields.createdAt, descending: true)
        .limit(limit);
    return _watchQuery(query, operationLabel: 'watch_latest_open_gigs').map(
      (snapshot) =>
          snapshot.docs.map(Gig.fromFirestore).toList(growable: false),
    );
  }

  bool _matchesFilters(Gig gig, GigFilters filters) {
    if (filters.onlyOpenSlots && gig.availableSlots <= 0) return false;

    if (filters.locationTypes.isNotEmpty &&
        !filters.locationTypes.contains(gig.locationType)) {
      return false;
    }

    if (filters.compensationTypes.isNotEmpty &&
        !filters.compensationTypes.contains(gig.compensationType)) {
      return false;
    }

    final term = filters.term.trim().toLowerCase();
    if (term.isNotEmpty) {
      final haystack = [
        gig.title,
        gig.description,
        gig.location?['label']?.toString() ?? '',
      ].join(' ').toLowerCase();
      if (!haystack.contains(term)) return false;
    }

    if (filters.genres.isNotEmpty && !gig.genres.any(filters.genres.contains)) {
      return false;
    }

    if (filters.requiredInstruments.isNotEmpty &&
        !gig.requiredInstruments.any(filters.requiredInstruments.contains)) {
      return false;
    }

    if (filters.requiredCrewRoles.isNotEmpty &&
        !gig.requiredCrewRoles.any(filters.requiredCrewRoles.contains)) {
      return false;
    }

    if (filters.requiredStudioServices.isNotEmpty &&
        !gig.requiredStudioServices.any(
          filters.requiredStudioServices.contains,
        )) {
      return false;
    }

    return true;
  }

  Stream<List<Gig>> watchMyGigs() {
    final query = _gigs
        .where(GigFields.creatorId, isEqualTo: _uid)
        .orderBy(GigFields.createdAt, descending: true);
    return _watchQuery(query, operationLabel: 'watch_my_gigs').map(
      (snapshot) =>
          snapshot.docs.map(Gig.fromFirestore).toList(growable: false),
    );
  }

  Stream<Gig?> watchGigById(String gigId) {
    return _watchDocument(
      _gigs.doc(gigId),
      operationLabel: 'watch_gig_by_id',
    ).map((snapshot) {
      if (!snapshot.exists) return null;
      return Gig.fromFirestore(snapshot);
    });
  }

  Future<String> createGig(GigDraft draft) async {
    await _ensureCanInteract();

    final openCount = await _getAggregateSnapshot(
      _gigs
          .where(GigFields.creatorId, isEqualTo: _uid)
          .where(GigFields.status, isEqualTo: _gigStatusValue(GigStatus.open))
          .count(),
      operationLabel: 'create_gig_open_count',
    );

    if ((openCount.count ?? 0) >= 5) {
      throw Exception('Voce ja atingiu o limite de 5 gigs abertas.');
    }

    if (draft.requiresFixedDate && draft.gigDate == null) {
      throw Exception('Selecione a data da gig.');
    }

    final doc = _gigs.doc();
    await _setDocument(doc, {
      GigFields.title: draft.title.trim(),
      GigFields.description: draft.description.trim(),
      GigFields.gigType: _gigTypeValue(draft.gigType),
      GigFields.status: _gigStatusValue(GigStatus.open),
      GigFields.dateMode: _gigDateModeValue(draft.dateMode),
      GigFields.gigDate: draft.gigDate == null
          ? null
          : Timestamp.fromDate(draft.gigDate!),
      GigFields.locationType: _gigLocationTypeValue(draft.locationType),
      GigFields.location: draft.location,
      GigFields.geohash: draft.geohash,
      GigFields.genres: draft.genres,
      GigFields.requiredInstruments: draft.requiredInstruments,
      GigFields.requiredCrewRoles: draft.requiredCrewRoles,
      GigFields.requiredStudioServices: draft.requiredStudioServices,
      GigFields.slotsTotal: draft.slotsTotal,
      GigFields.slotsFilled: 0,
      GigFields.compensationType: _compensationTypeValue(
        draft.compensationType,
      ),
      GigFields.compensationValue: draft.compensationValue,
      GigFields.creatorId: _uid,
      GigFields.applicantCount: 0,
      GigFields.createdAt: FieldValue.serverTimestamp(),
      GigFields.updatedAt: FieldValue.serverTimestamp(),
      GigFields.expiresAt: draft.gigDate == null
          ? null
          : Timestamp.fromDate(draft.gigDate!),
    }, operationLabel: 'create_gig_set');

    return doc.id;
  }

  Future<void> updateGig(String gigId, GigUpdate update) async {
    await _ensureCanInteract();
    final snapshot = await _getDocument(
      _gigs.doc(gigId),
      operationLabel: 'update_gig_get',
    );
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Gig nao encontrada.');
    }

    final gig = Gig.fromFirestore(snapshot);
    if (gig.creatorId != _uid) {
      throw Exception('Apenas o criador pode editar esta gig.');
    }

    final touchesRestrictedField =
        update.title != null ||
        update.gigType != null ||
        update.dateMode != null ||
        update.gigDate != null ||
        update.clearGigDate ||
        update.locationType != null ||
        update.location != null ||
        update.clearLocation ||
        update.genres != null ||
        update.requiredInstruments != null ||
        update.requiredCrewRoles != null ||
        update.requiredStudioServices != null ||
        update.slotsTotal != null ||
        update.compensationType != null ||
        update.compensationValue != null ||
        update.clearCompensationValue;

    if (gig.applicantCount > 0 && touchesRestrictedField) {
      throw Exception(
        'Depois da primeira candidatura, apenas a descricao pode ser editada.',
      );
    }

    final payload = <String, dynamic>{
      GigFields.updatedAt: FieldValue.serverTimestamp(),
    };

    if (update.title != null) payload[GigFields.title] = update.title!.trim();
    if (update.description != null) {
      payload[GigFields.description] = update.description!.trim();
    }
    if (update.gigType != null) {
      payload[GigFields.gigType] = _gigTypeValue(update.gigType!);
    }
    if (update.dateMode != null) {
      payload[GigFields.dateMode] = _gigDateModeValue(update.dateMode!);
    }
    if (update.clearGigDate) {
      payload[GigFields.gigDate] = null;
      payload[GigFields.expiresAt] = null;
    } else if (update.gigDate != null) {
      payload[GigFields.gigDate] = Timestamp.fromDate(update.gigDate!);
      payload[GigFields.expiresAt] = Timestamp.fromDate(update.gigDate!);
    }
    if (update.locationType != null) {
      payload[GigFields.locationType] = _gigLocationTypeValue(
        update.locationType!,
      );
    }
    if (update.clearLocation) {
      payload[GigFields.location] = null;
      payload[GigFields.geohash] = null;
    } else {
      if (update.location != null) {
        payload[GigFields.location] = update.location;
      }
      if (update.locationType == GigLocationType.remote) {
        payload[GigFields.geohash] = null;
      } else if (update.geohash != null) {
        payload[GigFields.geohash] = update.geohash;
      }
    }
    if (update.genres != null) payload[GigFields.genres] = update.genres;
    if (update.requiredInstruments != null) {
      payload[GigFields.requiredInstruments] = update.requiredInstruments;
    }
    if (update.requiredCrewRoles != null) {
      payload[GigFields.requiredCrewRoles] = update.requiredCrewRoles;
    }
    if (update.requiredStudioServices != null) {
      payload[GigFields.requiredStudioServices] = update.requiredStudioServices;
    }
    if (update.slotsTotal != null) {
      payload[GigFields.slotsTotal] = update.slotsTotal;
    }
    if (update.compensationType != null) {
      payload[GigFields.compensationType] = _compensationTypeValue(
        update.compensationType!,
      );
    }
    if (update.clearCompensationValue) {
      payload[GigFields.compensationValue] = null;
    } else if (update.compensationValue != null) {
      payload[GigFields.compensationValue] = update.compensationValue;
    }

    await _updateDocument(
      _gigs.doc(gigId),
      payload,
      operationLabel: 'update_gig_write',
    );
  }

  Future<void> closeGig(String gigId) async {
    await _updateGigStatus(gigId, GigStatus.closed);
  }

  Future<void> cancelGig(String gigId) async {
    await _updateGigStatus(gigId, GigStatus.cancelled);
  }

  Future<void> _updateGigStatus(String gigId, GigStatus status) async {
    await _ensureCanInteract();
    final snapshot = await _getDocument(
      _gigs.doc(gigId),
      operationLabel: 'update_gig_status_get',
    );
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Gig nao encontrada.');
    }

    final gig = Gig.fromFirestore(snapshot);
    if (gig.creatorId != _uid) {
      throw Exception('Apenas o criador pode alterar esta gig.');
    }

    await _updateDocument(_gigs.doc(gigId), {
      GigFields.status: _gigStatusValue(status),
      GigFields.updatedAt: FieldValue.serverTimestamp(),
    }, operationLabel: 'update_gig_status_write');
  }

  Future<void> applyToGig(String gigId, String message) async {
    await _ensureCanInteract();

    final gigSnapshot = await _getDocument(
      _gigs.doc(gigId),
      operationLabel: 'apply_to_gig_get_gig',
    );
    if (!gigSnapshot.exists || gigSnapshot.data() == null) {
      throw Exception('Gig nao encontrada.');
    }

    final gig = Gig.fromFirestore(gigSnapshot);
    if (gig.creatorId == _uid) {
      throw Exception('Voce nao pode se candidatar a propria gig.');
    }
    if (gig.status != GigStatus.open) {
      throw Exception('Esta gig nao esta mais aberta.');
    }
    if (gig.isFull) {
      throw Exception('As vagas desta gig ja foram preenchidas.');
    }

    final applicationRef = _applications(gigId).doc(_uid);
    final existing = await _getDocument(
      applicationRef,
      operationLabel: 'apply_to_gig_check_existing',
    );
    if (existing.exists) {
      throw Exception('Voce ja tem uma candidatura ativa para esta gig.');
    }

    await _setDocument(applicationRef, {
      GigFields.applicantId: _uid,
      GigFields.message: message.trim(),
      GigFields.status: _applicationStatusValue(ApplicationStatus.pending),
      GigFields.appliedAt: FieldValue.serverTimestamp(),
      GigFields.respondedAt: null,
    }, operationLabel: 'apply_to_gig_set_application');
  }

  Future<void> withdrawApplication(String gigId) async {
    await _ensureCanInteract();
    final applicationRef = _applications(gigId).doc(_uid);
    final snapshot = await _getDocument(
      applicationRef,
      operationLabel: 'withdraw_application_get',
    );
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Candidatura nao encontrada.');
    }

    final status = snapshot.data()![GigFields.status] as String?;
    if (status == _applicationStatusValue(ApplicationStatus.rejected) ||
        status == _applicationStatusValue(ApplicationStatus.gigCancelled)) {
      throw Exception('Esta candidatura nao pode mais ser retirada.');
    }

    await _deleteDocument(
      applicationRef,
      operationLabel: 'withdraw_application_delete',
    );
  }

  Stream<List<GigApplication>> watchApplications(String gigId) {
    final query = _applications(
      gigId,
    ).orderBy(GigFields.appliedAt, descending: true);
    return _watchQuery(query, operationLabel: 'watch_gig_applications').map(
      (snapshot) => snapshot.docs
          .map((doc) => GigApplication.fromFirestore(doc, gigId: gigId))
          .toList(growable: false),
    );
  }

  Future<void> updateApplicationStatus(
    String gigId,
    String applicantId,
    ApplicationStatus status,
  ) async {
    await _ensureCanInteract();
    final gigSnapshot = await _getDocument(
      _gigs.doc(gigId),
      operationLabel: 'update_application_status_get_gig',
    );
    if (!gigSnapshot.exists || gigSnapshot.data() == null) {
      throw Exception('Gig nao encontrada.');
    }
    final gig = Gig.fromFirestore(gigSnapshot);
    if (gig.creatorId != _uid) {
      throw Exception('Apenas o criador pode gerenciar candidaturas.');
    }

    final applicationRef = _applications(gigId).doc(applicantId);
    final applicationSnapshot = await _getDocument(
      applicationRef,
      operationLabel: 'update_application_status_get_application',
    );
    if (!applicationSnapshot.exists || applicationSnapshot.data() == null) {
      throw Exception('Candidatura nao encontrada.');
    }

    final current = _applicationStatusFromString(
      applicationSnapshot.data()![GigFields.status] as String?,
    );

    if (current == ApplicationStatus.rejected &&
        status == ApplicationStatus.accepted) {
      throw Exception('Candidatura recusada nao pode ser aceita depois.');
    }

    if (current == ApplicationStatus.accepted &&
        status == ApplicationStatus.rejected) {
      throw Exception('Nao e permitido rebaixar uma candidatura aceita.');
    }

    if (current == status) return;

    if (status == ApplicationStatus.accepted) {
      final aggregate = await _getAggregateSnapshot(
        _applications(gigId)
            .where(
              GigFields.status,
              isEqualTo: _applicationStatusValue(ApplicationStatus.accepted),
            )
            .count(),
        operationLabel: 'update_application_status_count_accepted',
      );
      if ((aggregate.count ?? 0) >= gig.slotsTotal) {
        throw Exception('Nao ha vagas disponiveis para novo aceite.');
      }
    }

    if (current != ApplicationStatus.pending &&
        current != ApplicationStatus.accepted) {
      throw Exception('Esta candidatura nao pode mais ser alterada.');
    }

    await _updateDocument(applicationRef, {
      GigFields.status: _applicationStatusValue(status),
      GigFields.respondedAt: FieldValue.serverTimestamp(),
    }, operationLabel: 'update_application_status_write');
  }

  Stream<List<GigApplication>> watchMyApplications() {
    final query = _firestore
        .collectionGroup(FirestoreCollections.gigApplications)
        .where(GigFields.applicantId, isEqualTo: _uid)
        .orderBy(GigFields.appliedAt, descending: true);

    return _watchQuery(query, operationLabel: 'watch_my_applications').asyncMap(
      (snapshot) async {
        final gigIds = snapshot.docs
            .map((doc) => doc.reference.parent.parent?.id)
            .whereType<String>()
            .toSet()
            .toList(growable: false);

        final gigsById = await _loadGigsByIds(gigIds);

        return snapshot.docs
            .map((doc) {
              final gigId = doc.reference.parent.parent?.id ?? '';
              final gig = gigsById[gigId];
              return GigApplication.fromFirestore(
                doc,
                gigId: gigId,
                gigTitle: gig?.title,
                gigType: gig?.gigType,
                gigStatus: gig?.status,
                creatorId: gig?.creatorId,
              );
            })
            .toList(growable: false);
      },
    );
  }

  Stream<GigApplication?> watchMyApplicationForGig(String gigId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _watchDocument(
      _applications(gigId).doc(user.uid),
      operationLabel: 'watch_my_application_for_gig',
    ).map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }

      return GigApplication(
        id: snapshot.id,
        gigId: gigId,
        applicantId: (data[GigFields.applicantId] as String? ?? '').trim(),
        message: (data[GigFields.message] as String? ?? '').trim(),
        status: _applicationStatusFromString(data[GigFields.status] as String?),
        appliedAt: _readGigApplicationDateTime(data[GigFields.appliedAt]),
        respondedAt: _readGigApplicationDateTime(data[GigFields.respondedAt]),
      );
    });
  }

  Future<Map<String, Gig>> _loadGigsByIds(List<String> gigIds) async {
    if (gigIds.isEmpty) return const {};
    final gigs = <String, Gig>{};

    for (final chunk in _chunk(gigIds, 10)) {
      final snapshot = await _getQuerySnapshot(
        _gigs.where(FieldPath.documentId, whereIn: chunk),
        operationLabel: 'load_gigs_by_ids',
      );
      for (final doc in snapshot.docs) {
        gigs[doc.id] = Gig.fromFirestore(doc);
      }
    }

    return gigs;
  }

  Future<bool> hasApplied(String gigId) async {
    final snapshot = await _getDocument(
      _applications(gigId).doc(_uid),
      operationLabel: 'has_applied',
    );
    return snapshot.exists;
  }

  Future<void> submitReview(GigReviewDraft review) async {
    await _ensureCanInteract();

    if (review.rating < 1 || review.rating > 5) {
      throw Exception('A nota deve estar entre 1 e 5.');
    }

    final gigSnapshot = await _getDocument(
      _gigs.doc(review.gigId),
      operationLabel: 'submit_review_get_gig',
    );
    if (!gigSnapshot.exists || gigSnapshot.data() == null) {
      throw Exception('Gig nao encontrada.');
    }
    final gig = Gig.fromFirestore(gigSnapshot);

    if (gig.status != GigStatus.closed) {
      throw Exception(
        'A avaliacao so pode ser enviada apos a gig ser fechada.',
      );
    }

    final reviewType = await _resolveReviewType(
      gig: gig,
      reviewedUserId: review.reviewedUserId,
    );

    final reviewId = '${review.gigId}_${_uid}_${review.reviewedUserId}';
    final existing = await _getDocument(
      _reviews.doc(reviewId),
      operationLabel: 'submit_review_check_existing',
    );
    if (existing.exists) {
      throw Exception('Voce ja avaliou este usuario nesta gig.');
    }

    await _setDocument(_reviews.doc(reviewId), {
      GigFields.gigId: review.gigId,
      GigFields.reviewerId: _uid,
      GigFields.reviewedUserId: review.reviewedUserId,
      GigFields.rating: review.rating,
      GigFields.comment: review.comment?.trim(),
      GigFields.reviewType: _reviewTypeValue(reviewType),
      GigFields.createdAt: FieldValue.serverTimestamp(),
    }, operationLabel: 'submit_review_write');
  }

  Future<ReviewType> _resolveReviewType({
    required Gig gig,
    required String reviewedUserId,
  }) async {
    if (_uid == gig.creatorId) {
      final application = await _getDocument(
        _applications(gig.id).doc(reviewedUserId),
        operationLabel: 'resolve_review_type_target_application',
      );
      if (!application.exists || application.data() == null) {
        throw Exception('Participante nao encontrado nesta gig.');
      }

      final status = _applicationStatusFromString(
        application.data()![GigFields.status] as String?,
      );
      if (status != ApplicationStatus.accepted) {
        throw Exception('Apenas participantes aceitos podem ser avaliados.');
      }

      return ReviewType.creatorToParticipant;
    }

    final ownApplication = await _getDocument(
      _applications(gig.id).doc(_uid),
      operationLabel: 'resolve_review_type_own_application',
    );
    if (!ownApplication.exists || ownApplication.data() == null) {
      throw Exception('Voce nao participou desta gig.');
    }

    final status = _applicationStatusFromString(
      ownApplication.data()![GigFields.status] as String?,
    );
    if (status != ApplicationStatus.accepted ||
        reviewedUserId != gig.creatorId) {
      throw Exception('Apenas o criador pode ser avaliado por participantes.');
    }

    return ReviewType.participantToCreator;
  }

  Stream<List<GigReview>> watchReviewsForUser(String userId) {
    final query = _reviews
        .where(GigFields.reviewedUserId, isEqualTo: userId)
        .orderBy(GigFields.createdAt, descending: true);
    return _watchQuery(query, operationLabel: 'watch_reviews_for_user').map(
      (snapshot) =>
          snapshot.docs.map(GigReview.fromFirestore).toList(growable: false),
    );
  }

  Future<double?> getAverageRating(String userId) async {
    final snapshot = await _getQuerySnapshot(
      _reviews.where(GigFields.reviewedUserId, isEqualTo: userId),
      operationLabel: 'get_average_rating',
    );
    if (snapshot.docs.isEmpty) return null;

    final sum = snapshot.docs.fold<int>(0, (total, doc) {
      return total + ((doc.data()[GigFields.rating] as num?)?.toInt() ?? 0);
    });
    return sum / snapshot.docs.length;
  }

  Future<List<GigReviewOpportunity>> getPendingReviewsForCurrentUser() async {
    await _ensureCanInteract();

    final opportunities = <GigReviewOpportunity>[];
    final userIds = <String>{};

    final ownGigs = await _getQuerySnapshot(
      _gigs
          .where(GigFields.creatorId, isEqualTo: _uid)
          .where(
            GigFields.status,
            isEqualTo: _gigStatusValue(GigStatus.closed),
          ),
      operationLabel: 'pending_reviews_load_own_gigs',
    );

    for (final doc in ownGigs.docs) {
      final gig = Gig.fromFirestore(doc);
      final applications = await _getQuerySnapshot(
        _applications(gig.id).where(
          GigFields.status,
          isEqualTo: _applicationStatusValue(ApplicationStatus.accepted),
        ),
        operationLabel: 'pending_reviews_load_accepted_applications',
      );

      for (final applicationDoc in applications.docs) {
        final targetId = applicationDoc.id;
        final alreadyReviewed = await _getDocument(
          _reviews.doc('${gig.id}_${_uid}_$targetId'),
          operationLabel: 'pending_reviews_check_creator_review',
        );
        if (alreadyReviewed.exists) continue;
        userIds.add(targetId);
        opportunities.add(
          GigReviewOpportunity(
            gigId: gig.id,
            gigTitle: gig.title,
            reviewedUserId: targetId,
            reviewedUserName: '',
            reviewType: ReviewType.creatorToParticipant,
          ),
        );
      }
    }

    try {
      final acceptedApplications = await _firestore
          .collectionGroup(FirestoreCollections.gigApplications)
          .where(GigFields.applicantId, isEqualTo: _uid)
          .where(
            GigFields.status,
            isEqualTo: _applicationStatusValue(ApplicationStatus.accepted),
          )
          .get();

      for (final doc in acceptedApplications.docs) {
        final gigId = doc.reference.parent.parent?.id;
        if (gigId == null || gigId.isEmpty) continue;
        final gigSnapshot = await _getDocument(
          _gigs.doc(gigId),
          operationLabel: 'pending_reviews_get_gig',
        );
        if (!gigSnapshot.exists || gigSnapshot.data() == null) continue;

        final gig = Gig.fromFirestore(gigSnapshot);
        if (gig.status != GigStatus.closed) continue;

        final reviewId = '${gig.id}_${_uid}_${gig.creatorId}';
        final alreadyReviewed = await _getDocument(
          _reviews.doc(reviewId),
          operationLabel: 'pending_reviews_check_participant_review',
        );
        if (alreadyReviewed.exists) continue;

        userIds.add(gig.creatorId);
        opportunities.add(
          GigReviewOpportunity(
            gigId: gig.id,
            gigTitle: gig.title,
            reviewedUserId: gig.creatorId,
            reviewedUserName: '',
            reviewType: ReviewType.participantToCreator,
          ),
        );
      }
    } on FirebaseException catch (error) {
      if (!_isSecurityContextFailure(error)) {
        rethrow;
      }

      AppLogger.info(
        'GigRepository skipped participant review opportunities due to '
        'security context failure on collectionGroup query. '
        'Participant review flow will remain hidden for this session.',
      );
    }

    if (opportunities.isEmpty) return const [];

    final users = await _loadUsersByIds(userIds.toList(growable: false));
    return opportunities
        .map(
          (opportunity) => GigReviewOpportunity(
            gigId: opportunity.gigId,
            gigTitle: opportunity.gigTitle,
            reviewedUserId: opportunity.reviewedUserId,
            reviewedUserName:
                users[opportunity.reviewedUserId]?.appDisplayName ?? 'Usuario',
            reviewedUserPhoto: users[opportunity.reviewedUserId]?.foto,
            reviewType: opportunity.reviewType,
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, AppUser>> _loadUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final users = <String, AppUser>{};

    for (final chunk in _chunk(ids, 10)) {
      final snapshot = await _getQuerySnapshot(
        _firestore
            .collection(FirestoreCollections.users)
            .where(FieldPath.documentId, whereIn: chunk),
        operationLabel: 'load_users_by_ids',
      );

      for (final doc in snapshot.docs) {
        users[doc.id] = AppUser.fromJson(doc.data());
      }
    }

    return users;
  }

  Future<Map<String, AppUser>> getUsersByIds(List<String> ids) {
    return _loadUsersByIds(ids);
  }

  List<List<String>> _chunk(List<String> values, int size) {
    final chunks = <List<String>>[];
    for (var i = 0; i < values.length; i += size) {
      final end = (i + size) > values.length ? values.length : i + size;
      chunks.add(values.sublist(i, end));
    }
    return chunks;
  }
}

DateTime? _readGigApplicationDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

String _gigTypeValue(GigType value) {
  switch (value) {
    case GigType.liveShow:
      return 'show_ao_vivo';
    case GigType.privateEvent:
      return 'evento_privado';
    case GigType.recording:
      return 'gravacao';
    case GigType.rehearsalJam:
      return 'ensaio_jam';
    case GigType.other:
      return 'outro';
  }
}

String _gigStatusValue(GigStatus value) {
  switch (value) {
    case GigStatus.open:
      return 'open';
    case GigStatus.closed:
      return 'closed';
    case GigStatus.expired:
      return 'expired';
    case GigStatus.cancelled:
      return 'cancelled';
  }
}

String _gigDateModeValue(GigDateMode value) {
  switch (value) {
    case GigDateMode.fixedDate:
      return 'fixed_date';
    case GigDateMode.toBeArranged:
      return 'to_be_arranged';
    case GigDateMode.unspecified:
      return 'unspecified';
  }
}

String _gigLocationTypeValue(GigLocationType value) {
  switch (value) {
    case GigLocationType.onsite:
      return 'presencial';
    case GigLocationType.remote:
      return 'remoto';
  }
}

String _compensationTypeValue(CompensationType value) {
  switch (value) {
    case CompensationType.fixed:
      return 'fixed';
    case CompensationType.negotiable:
      return 'negotiable';
    case CompensationType.volunteer:
      return 'volunteer';
    case CompensationType.toBeDefined:
      return 'tbd';
  }
}

String _applicationStatusValue(ApplicationStatus value) {
  switch (value) {
    case ApplicationStatus.pending:
      return 'pending';
    case ApplicationStatus.accepted:
      return 'accepted';
    case ApplicationStatus.rejected:
      return 'rejected';
    case ApplicationStatus.gigCancelled:
      return 'gig_cancelled';
  }
}

ApplicationStatus _applicationStatusFromString(String? value) {
  return ApplicationStatus.values.firstWhere(
    (item) => _applicationStatusValue(item) == value,
    orElse: () => ApplicationStatus.pending,
  );
}

String _reviewTypeValue(ReviewType value) {
  switch (value) {
    case ReviewType.creatorToParticipant:
      return 'creator_to_participant';
    case ReviewType.participantToCreator:
      return 'participant_to_creator';
  }
}
