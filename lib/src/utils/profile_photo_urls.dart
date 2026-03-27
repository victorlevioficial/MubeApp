String? resolveProfilePhotoPreviewUrl({
  String? thumbnailUrl,
  String? photoUrl,
}) {
  final thumbnail = thumbnailUrl?.trim() ?? '';
  if (thumbnail.isNotEmpty) return thumbnail;

  final full = photoUrl?.trim() ?? '';
  if (full.isNotEmpty) return full;

  return null;
}

String appendCacheBuster(String url, {required int version}) {
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}v=$version';
}

String? appendCacheBusterIfPresent(String? url, {required int version}) {
  final normalized = url?.trim() ?? '';
  if (normalized.isEmpty) return null;
  return appendCacheBuster(normalized, version: version);
}
