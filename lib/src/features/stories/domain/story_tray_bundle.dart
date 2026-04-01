import 'story_item.dart';

class StoryTrayBundle {
  const StoryTrayBundle({
    required this.ownerUid,
    required this.ownerName,
    required this.ownerType,
    required this.stories,
    required this.hasUnseen,
    this.ownerPhoto,
    this.ownerPhotoPreview,
    this.isFavorite = false,
    this.isCurrentUser = false,
  });

  final String ownerUid;
  final String ownerName;
  final String? ownerPhoto;
  final String? ownerPhotoPreview;
  final String ownerType;
  final List<StoryItem> stories;
  final bool hasUnseen;
  final bool isFavorite;
  final bool isCurrentUser;

  StoryItem? get latestStory => stories.isEmpty ? null : stories.last;

  bool get hasActiveStories => stories.isNotEmpty;

  DateTime get latestStoryAt =>
      latestStory?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  StoryTrayBundle copyWith({
    String? ownerUid,
    String? ownerName,
    String? ownerPhoto,
    String? ownerPhotoPreview,
    String? ownerType,
    List<StoryItem>? stories,
    bool? hasUnseen,
    bool? isFavorite,
    bool? isCurrentUser,
  }) {
    return StoryTrayBundle(
      ownerUid: ownerUid ?? this.ownerUid,
      ownerName: ownerName ?? this.ownerName,
      ownerPhoto: ownerPhoto ?? this.ownerPhoto,
      ownerPhotoPreview: ownerPhotoPreview ?? this.ownerPhotoPreview,
      ownerType: ownerType ?? this.ownerType,
      stories: stories ?? this.stories,
      hasUnseen: hasUnseen ?? this.hasUnseen,
      isFavorite: isFavorite ?? this.isFavorite,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
