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
      type: FeedSectionType.artists,
      title: 'Perfis em destaque',
      filterValue: 'profissional',
    ),
    FeedSection(type: FeedSectionType.nearby, title: 'Perto de você'),
    FeedSection(
      type: FeedSectionType.bands,
      title: 'Bandas',
      filterValue: 'banda',
    ),
    FeedSection(
      type: FeedSectionType.technicians,
      title: 'Equipe Técnica',
      filterValue: 'Equipe Técnica',
    ),
    FeedSection(
      type: FeedSectionType.studios,
      title: 'Estúdios',
      filterValue: 'estudio',
    ),
  ];
}
