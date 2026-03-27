import 'package:meta/meta.dart';

/// Types of media that can be in the gallery.
enum MediaType { photo, video }

/// Represents a single media item in the user's gallery.
@immutable
class MediaItem {
  /// Unique identifier for this media item.
  final String id;

  /// Download URL from Firebase Storage.
  final String url;

  /// Type of media (photo or video).
  final MediaType type;

  /// Preview thumbnail URL.
  ///
  /// For videos, this is the generated poster frame.
  /// For photos, this may contain a smaller variant for grid previews.
  final String? thumbnailUrl;

  /// Medium-sized URL for photos when available.
  final String? mediumUrl;

  /// Large-sized URL for photos when available.
  final String? largeUrl;

  /// Order in the gallery (0 = first/main).
  final int order;

  /// Local file path for optimistic UI preview (before upload completes).
  final String? localPath;

  /// Local thumbnail path for optimistic video preview.
  final String? localThumbnailPath;

  /// Whether this item is currently being uploaded.
  final bool isUploading;

  /// Whether this item is currently being deleted.
  final bool isDeleting;

  /// Upload progress (0.0 to 1.0) for this individual item.
  final double uploadProgress;

  const MediaItem({
    required this.id,
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.mediumUrl,
    this.largeUrl,
    required this.order,
    this.localPath,
    this.localThumbnailPath,
    this.isUploading = false,
    this.isDeleting = false,
    this.uploadProgress = 0.0,
  });

  /// Whether this item has a local preview available.
  bool get hasLocalPreview => localPath != null && localPath!.isNotEmpty;
  bool get isProcessing => isUploading || isDeleting;

  /// Best image URL for grid/list previews.
  String get previewUrl {
    if (type == MediaType.video) {
      return _firstNonEmpty([thumbnailUrl, url]);
    }
    return _firstNonEmpty([thumbnailUrl, mediumUrl, largeUrl, url]);
  }

  /// Best image URL for full-screen photo viewing.
  String get viewerUrl {
    if (type == MediaType.video) return url;
    return _firstNonEmpty([largeUrl, mediumUrl, thumbnailUrl, url]);
  }

  MediaItem copyWith({
    String? id,
    String? url,
    MediaType? type,
    String? thumbnailUrl,
    String? mediumUrl,
    String? largeUrl,
    int? order,
    String? localPath,
    String? localThumbnailPath,
    bool? isUploading,
    bool? isDeleting,
    double? uploadProgress,
  }) {
    return MediaItem(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediumUrl: mediumUrl ?? this.mediumUrl,
      largeUrl: largeUrl ?? this.largeUrl,
      order: order ?? this.order,
      localPath: localPath ?? this.localPath,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      isUploading: isUploading ?? this.isUploading,
      isDeleting: isDeleting ?? this.isDeleting,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type == MediaType.video ? 'video' : 'photo',
      'thumbnailUrl': thumbnailUrl,
      'mediumUrl': mediumUrl,
      'largeUrl': largeUrl,
      'order': order,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] == 'video' ? MediaType.video : MediaType.photo,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      mediumUrl: json['mediumUrl'] as String?,
      largeUrl: json['largeUrl'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  static String _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }
}
