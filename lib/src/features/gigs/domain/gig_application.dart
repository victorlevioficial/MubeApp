import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'application_status.dart';
import 'gig_status.dart';
import 'gig_type.dart';

part 'gig_application.freezed.dart';
part 'gig_application.g.dart';

@freezed
abstract class GigApplication with _$GigApplication {
  const factory GigApplication({
    required String id,
    required String gigId,
    @JsonKey(name: 'applicant_id') required String applicantId,
    required String message,
    required ApplicationStatus status,
    @JsonKey(name: 'applied_at') DateTime? appliedAt,
    @JsonKey(name: 'responded_at') DateTime? respondedAt,
    String? gigTitle,
    GigType? gigType,
    GigStatus? gigStatus,
    String? creatorId,
  }) = _GigApplication;

  const GigApplication._();

  factory GigApplication.fromJson(Map<String, dynamic> json) =>
      _$GigApplicationFromJson(json);

  factory GigApplication.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    String? gigId,
    String? gigTitle,
    GigType? gigType,
    GigStatus? gigStatus,
    String? creatorId,
  }) {
    final data = doc.data();
    return GigApplication(
      id: doc.id,
      gigId: gigId ?? (doc.reference.parent.parent?.id ?? ''),
      applicantId: (data['applicant_id'] as String? ?? '').trim(),
      message: (data['message'] as String? ?? '').trim(),
      status: _parseApplicationStatus(data['status'] as String?),
      appliedAt: _readApplicationDateTime(data['applied_at']),
      respondedAt: _readApplicationDateTime(data['responded_at']),
      gigTitle: gigTitle,
      gigType: gigType,
      gigStatus: gigStatus,
      creatorId: creatorId,
    );
  }

  bool get isTerminal =>
      status == ApplicationStatus.rejected ||
      status == ApplicationStatus.gigCancelled;
}

DateTime? _readApplicationDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

ApplicationStatus _parseApplicationStatus(String? value) {
  return ApplicationStatus.values.firstWhere((item) {
    switch (item) {
      case ApplicationStatus.pending:
        return value == 'pending';
      case ApplicationStatus.accepted:
        return value == 'accepted';
      case ApplicationStatus.rejected:
        return value == 'rejected';
      case ApplicationStatus.gigCancelled:
        return value == 'gig_cancelled';
    }
  }, orElse: () => ApplicationStatus.pending);
}
