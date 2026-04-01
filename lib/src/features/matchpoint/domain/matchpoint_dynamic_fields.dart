Map<String, dynamic>? matchpointStringMapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is! Map) {
    return null;
  }

  final normalized = <String, dynamic>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key == null) continue;
    normalized[key.toString()] = entry.value;
  }

  return normalized;
}

List<String> matchpointStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  if (value is String) {
    final normalized = value.trim();
    return normalized.isEmpty ? const [] : <String>[normalized];
  }

  return const [];
}

List<Map<String, dynamic>> matchpointStringMapList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map(matchpointStringMapOrNull)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}
