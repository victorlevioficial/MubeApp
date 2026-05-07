import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryMediaType { image, video }

enum StoryStatus { active, processing, uploading, failed, expired, deleted }

class StoryItem {
  const StoryItem({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerType,
    required this.mediaType,
    required this.mediaUrl,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    this.ownerPhoto,
    this.ownerPhotoPreview,
    this.thumbnailUrl,
    this.caption,
    this.publishedDayKey,
    this.durationSeconds,
    this.aspectRatio,
    this.viewersCount = 0,
  });

  final String id;
  final String ownerUid;
  final String ownerName;
  final String? ownerPhoto;
  final String? ownerPhotoPreview;
  final String ownerType;
  final StoryMediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? publishedDayKey;
  final int? durationSeconds;
  final double? aspectRatio;
  final int viewersCount;
  final StoryStatus status;

  bool get isVideo => mediaType == StoryMediaType.video;

  bool get isActive =>
      status == StoryStatus.active && expiresAt.isAfter(DateTime.now());

  StoryItem copyWith({
    String? id,
    String? ownerUid,
    String? ownerName,
    String? ownerPhoto,
    String? ownerPhotoPreview,
    String? ownerType,
    StoryMediaType? mediaType,
    String? mediaUrl,
    String? thumbnailUrl,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? publishedDayKey,
    int? durationSeconds,
    double? aspectRatio,
    int? viewersCount,
    StoryStatus? status,
  }) {
    return StoryItem(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerName: ownerName ?? this.ownerName,
      ownerPhoto: ownerPhoto ?? this.ownerPhoto,
      ownerPhotoPreview: ownerPhotoPreview ?? this.ownerPhotoPreview,
      ownerType: ownerType ?? this.ownerType,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      publishedDayKey: publishedDayKey ?? this.publishedDayKey,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      viewersCount: viewersCount ?? this.viewersCount,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_uid': ownerUid,
      'owner_name': ownerName,
      'owner_photo': ownerPhoto,
      'owner_photo_preview': ownerPhotoPreview,
      'owner_type': ownerType,
      'media_type': mediaType.name,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'published_day_key': publishedDayKey,
      'duration_seconds': durationSeconds,
      'aspect_ratio': aspectRatio,
      'viewers_count': viewersCount,
      'status': status.name,
    };
  }

  factory StoryItem.fromJson(Map<String, dynamic> json, {String? id}) {
    return StoryItem(
      id: (id ?? json['id'] as String? ?? '').trim(),
      ownerUid: (json['owner_uid'] as String? ?? '').trim(),
      ownerName: (json['owner_name'] as String? ?? '').trim(),
      ownerPhoto: json['owner_photo'] as String?,
      ownerPhotoPreview: json['owner_photo_preview'] as String?,
      ownerType: (json['owner_type'] as String? ?? '').trim(),
      mediaType: _readMediaType(json['media_type']),
      mediaUrl: (json['media_url'] as String? ?? '').trim(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      createdAt: _readDateTime(json['created_at']),
      expiresAt: _readDateTime(json['expires_at']),
      publishedDayKey: json['published_day_key'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      aspectRatio: (json['aspect_ratio'] as num?)?.toDouble(),
      viewersCount: (json['viewers_count'] as num?)?.toInt() ?? 0,
      status: _readStatus(json['status']),
    );
  }

  static StoryMediaType _readMediaType(dynamic raw) {
    return raw == 'video' ? StoryMediaType.video : StoryMediaType.image;
  }

  static StoryStatus _readStatus(dynamic raw) {
    switch (raw) {
      case 'processing':
        return StoryStatus.processing;
      case 'uploading':
        return StoryStatus.uploading;
      case 'failed':
        return StoryStatus.failed;
      case 'expired':
        return StoryStatus.expired;
      case 'deleted':
        return StoryStatus.deleted;
      default:
        return StoryStatus.active;
    }
  }

  static DateTime _readDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
