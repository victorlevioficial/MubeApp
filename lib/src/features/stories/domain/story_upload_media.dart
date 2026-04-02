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

  StoryUploadMedia copyWith({
    File? file,
    File? thumbnailFile,
    StoryMediaType? mediaType,
    double? aspectRatio,
    bool? fromCamera,
    int? durationSeconds,
  }) {
    return StoryUploadMedia(
      file: file ?? this.file,
      thumbnailFile: thumbnailFile ?? this.thumbnailFile,
      mediaType: mediaType ?? this.mediaType,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      fromCamera: fromCamera ?? this.fromCamera,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}
