import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';

void main() {
  Gig buildGig({
    GigStatus status = GigStatus.open,
    GigDateMode dateMode = GigDateMode.unspecified,
    DateTime? gigDate,
    int slotsTotal = 3,
    int slotsFilled = 0,
    int applicantCount = 0,
  }) {
    return Gig(
      id: 'gig-1',
      title: 'Procuro baterista',
      description: 'Gig para show pop rock com ensaio previo.',
      gigType: GigType.liveShow,
      status: status,
      dateMode: dateMode,
      gigDate: gigDate,
      locationType: GigLocationType.onsite,
      slotsTotal: slotsTotal,
      slotsFilled: slotsFilled,
      compensationType: CompensationType.fixed,
      compensationValue: 500,
      creatorId: 'creator-1',
      applicantCount: applicantCount,
    );
  }

  group('Gig', () {
    test('availableSlots never returns negative values', () {
      final gig = buildGig(slotsTotal: 1, slotsFilled: 4);

      expect(gig.availableSlots, 0);
      expect(gig.isFull, isTrue);
    });

    test('canEditAllFields only when open with no applications', () {
      expect(buildGig(applicantCount: 0).canEditAllFields, isTrue);
      expect(buildGig(applicantCount: 2).canEditAllFields, isFalse);
      expect(buildGig(status: GigStatus.closed).canEditAllFields, isFalse);
    });

    test('canEditDescriptionOnly when open and already has applications', () {
      expect(buildGig(applicantCount: 1).canEditDescriptionOnly, isTrue);
      expect(buildGig(applicantCount: 0).canEditDescriptionOnly, isFalse);
      expect(
        buildGig(
          applicantCount: 2,
          status: GigStatus.cancelled,
        ).canEditDescriptionOnly,
        isFalse,
      );
    });

    test('isExpiredByDate only for fixed-date gigs in the past', () {
      expect(
        buildGig(
          dateMode: GigDateMode.fixedDate,
          gigDate: DateTime.now().subtract(const Duration(days: 1)),
        ).isExpiredByDate,
        isTrue,
      );
      expect(
        buildGig(
          dateMode: GigDateMode.fixedDate,
          gigDate: DateTime.now().add(const Duration(days: 1)),
        ).isExpiredByDate,
        isFalse,
      );
      expect(
        buildGig(
          dateMode: GigDateMode.toBeArranged,
          gigDate: DateTime.now().subtract(const Duration(days: 10)),
        ).isExpiredByDate,
        isFalse,
      );
    });
  });
}
