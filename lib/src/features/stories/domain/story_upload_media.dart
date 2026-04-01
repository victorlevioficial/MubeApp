import 'dart:io';

import 'story_item.dart';

class StoryUploadMedia {
  const StoryUploadMedia({
    required this.file,
    required this.mediaType,
    required this.aspectRatio,
    required this.fromCamera,
    this.thumbnailFile,
    this.durationSeconds,
  });

  final File file;
  final File? thumbnailFile;
  final StoryMediaType mediaType;
  final double aspectRatio;
  final bool fromCamera;
  final int? durationSeconds;
}
