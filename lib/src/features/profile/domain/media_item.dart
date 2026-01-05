/// Types of media that can be in the gallery.
enum MediaType { photo, video }

/// Represents a single media item in the user's gallery.
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

  const MediaItem({
    required this.id,
    required this.url,
    required this.type,
    this.thumbnailUrl,
    required this.order,
  });

  MediaItem copyWith({
    String? id,
    String? url,
    MediaType? type,
    String? thumbnailUrl,
    int? order,
  }) {
    return MediaItem(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      order: order ?? this.order,
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
