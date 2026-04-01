import 'package:cloud_firestore/cloud_firestore.dart';

class StoryViewReceipt {
  const StoryViewReceipt({
    required this.viewerUid,
    required this.viewerName,
    required this.viewedAt,
    this.viewerPhoto,
  });

  final String viewerUid;
  final String viewerName;
  final String? viewerPhoto;
  final DateTime viewedAt;

  factory StoryViewReceipt.fromJson(Map<String, dynamic> json, {String? id}) {
    final rawViewedAt = json['viewed_at'];
    final viewedAt = rawViewedAt is Timestamp
        ? rawViewedAt.toDate()
        : DateTime.tryParse(rawViewedAt?.toString() ?? '') ?? DateTime.now();

    return StoryViewReceipt(
      viewerUid: (id ?? json['viewer_uid'] as String? ?? '').trim(),
      viewerName: (json['viewer_name'] as String? ?? '').trim(),
      viewerPhoto: json['viewer_photo'] as String?,
      viewedAt: viewedAt,
    );
  }
}
