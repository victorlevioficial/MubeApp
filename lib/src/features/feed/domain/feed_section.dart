import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// Enum for feed section types.
enum FeedSectionType { nearby, artists, bands, technicians, studios, venues }

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
      title: 'T\u00E9cnicos',
      filterValue: 'stage_tech',
    ),
    FeedSection(
      type: FeedSectionType.bands,
      title: 'Bandas pr\u00F3ximas',
      filterValue: 'banda',
    ),
    FeedSection(
      type: FeedSectionType.studios,
      title: 'Est\u00FAdios pr\u00F3ximos',
      filterValue: 'estudio',
    ),
    FeedSection(
      type: FeedSectionType.venues,
      title: 'Locais pr\u00F3ximos',
      filterValue: 'contratante',
    ),
  ];
}
