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

  /// Thumbnail URL for videos only.
  final String? thumbnailUrl;

  /// Order in the gallery (0 = first/main).
  final int order;

  /// Local file path for optimistic UI preview (before upload completes).
  final String? localPath;

  /// Local thumbnail path for optimistic video preview.
  final String? localThumbnailPath;

  /// Whether this item is currently being uploaded.
  final bool isUploading;

  /// Upload progress (0.0 to 1.0) for this individual item.
  final double uploadProgress;

  const MediaItem({
    required this.id,
    required this.url,
    required this.type,
    this.thumbnailUrl,
    required this.order,
    this.localPath,
    this.localThumbnailPath,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  /// Whether this item has a local preview available.
  bool get hasLocalPreview => localPath != null && localPath!.isNotEmpty;

  MediaItem copyWith({
    String? id,
    String? url,
    MediaType? type,
    String? thumbnailUrl,
    int? order,
    String? localPath,
    String? localThumbnailPath,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return MediaItem(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      order: order ?? this.order,
      localPath: localPath ?? this.localPath,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type == MediaType.video ? 'video' : 'photo',
      'thumbnailUrl': thumbnailUrl,
      'order': order,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] == 'video' ? MediaType.video : MediaType.photo,
      thumbnailUrl: json['thumbnailUrl'] as String?,
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
}
