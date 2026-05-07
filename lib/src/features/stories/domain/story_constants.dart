abstract final class StoryConstants {
  static const int maxStoriesPerDay = 3;
  static const int maxVideoDurationSeconds = 15;
  static const Duration storyLifetime = Duration(hours: 24);
  static const Duration imageDisplayDuration = Duration(seconds: 5);
  static const double targetAspectRatio = 9 / 16;
  // Tolerance widened slightly to account for pixel rounding done by the
  // image cropper on devices with non-standard screen densities (a 1079x1920
  // crop yields ~0.5620 instead of 0.5625, for example).
  static const double targetAspectRatioTolerance = 0.04;
  static const double maxVerticalAspectRatio = 0.75;
  static const String storiesCollection = 'stories';
  static const String viewsSubcollection = 'views';
  static const String storySeenAuthorsSubcollection = 'story_seen_authors';
  static const String statusActive = 'active';
  static const String statusProcessing = 'processing';
  static const String statusUploading = 'uploading';
  static const String statusFailed = 'failed';
  static const String statusExpired = 'expired';
  static const String statusDeleted = 'deleted';

  static bool isSupportedStoryAspectRatio(double aspectRatio) {
    return aspectRatio > 0 && aspectRatio <= maxVerticalAspectRatio;
  }

  static bool isExactStoryPhotoAspectRatio(double aspectRatio) {
    return aspectRatio > 0 &&
        (aspectRatio - targetAspectRatio).abs() <= targetAspectRatioTolerance;
  }

  static bool isSupportedVideoAspectRatio(double aspectRatio) {
    return isSupportedStoryAspectRatio(aspectRatio);
  }

  static String buildPublishedDayKey(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
