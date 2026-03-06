enum VideoTranscodeStatus { pending, succeeded, failed, unknown }

class VideoTranscodeJobState {
  final VideoTranscodeStatus status;
  final String? transcodedUrl;
  final String? errorMessage;

  const VideoTranscodeJobState({
    required this.status,
    this.transcodedUrl,
    this.errorMessage,
  });

  bool get isReady =>
      status == VideoTranscodeStatus.succeeded &&
      transcodedUrl != null &&
      transcodedUrl!.trim().isNotEmpty;

  bool get isFailed => status == VideoTranscodeStatus.failed;
}

const Set<String> kSuccessfulVideoTranscodeStatuses = <String>{
  'succeeded',
  'succeeded_without_gallery_update',
};

const Set<String> kFailedVideoTranscodeStatuses = <String>{
  'failed',
  'error',
  'cancelled',
};

VideoTranscodeJobState parseVideoTranscodeJobState(Map<String, dynamic>? data) {
  if (data == null) {
    return const VideoTranscodeJobState(status: VideoTranscodeStatus.unknown);
  }

  final status = (data['status'] as String? ?? '').trim().toLowerCase();
  final transcodedUrl = (data['transcodedUrl'] as String?)?.trim();
  final errorMessage = (data['errorMessage'] as String?)?.trim();

  if (kSuccessfulVideoTranscodeStatuses.contains(status)) {
    return VideoTranscodeJobState(
      status: VideoTranscodeStatus.succeeded,
      transcodedUrl: transcodedUrl,
      errorMessage: errorMessage,
    );
  }

  if (kFailedVideoTranscodeStatuses.contains(status)) {
    return VideoTranscodeJobState(
      status: VideoTranscodeStatus.failed,
      transcodedUrl: transcodedUrl,
      errorMessage: errorMessage,
    );
  }

  if (status.isNotEmpty) {
    return VideoTranscodeJobState(
      status: VideoTranscodeStatus.pending,
      transcodedUrl: transcodedUrl,
      errorMessage: errorMessage,
    );
  }

  return VideoTranscodeJobState(
    status: VideoTranscodeStatus.unknown,
    transcodedUrl: transcodedUrl,
    errorMessage: errorMessage,
  );
}

bool isTranscodedVideoUrl(String url) {
  final normalized = url.toLowerCase();
  return normalized.contains('/gallery_videos_transcoded/') ||
      normalized.contains('%2fgallery_videos_transcoded%2f') ||
      normalized.contains('gallery_videos_transcoded%2f');
}
