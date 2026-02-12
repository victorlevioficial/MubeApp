import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// Enum for feed section types.
enum FeedSectionType { nearby, artists, bands, technicians, studios }

/// Model for a feed section with title and items.
@immutable
class FeedSection {
  final FeedSectionType type;
  final String title;
  final String? filterValue;

  const FeedSection({
    required this.type,
    required this.title,
    this.filterValue,
  });

  /// Predefined sections for the home feed.
  static const List<FeedSection> homeSections = [
    FeedSection(
      type: FeedSectionType.technicians,
      title: 'Equipe técnica',
      filterValue: 'crew',
    ),
    FeedSection(
      type: FeedSectionType.bands,
      title: 'Bandas próximas',
      filterValue: 'banda',
    ),
    FeedSection(
      type: FeedSectionType.studios,
      title: 'Estúdios próximos',
      filterValue: 'estudio',
    ),
  ];
}
