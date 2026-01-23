import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_filters.freezed.dart';

/// Categories for search filtering.
enum SearchCategory {
  /// Show all searchable profiles
  all,

  /// Professional musicians, singers, DJs, crew
  professionals,

  /// Musical bands/groups
  bands,

  /// Recording/rehearsal studios
  studios,
}

/// Professional subcategories (only applies when category is [SearchCategory.professionals])
enum ProfessionalSubcategory { singer, instrumentalist, crew, dj }

/// Represents the current search filter state.
@freezed
abstract class SearchFilters with _$SearchFilters {
  const factory SearchFilters({
    /// Text search term (normalized)
    @Default('') String term,

    /// Main category filter
    @Default(SearchCategory.all) SearchCategory category,

    /// Professional subcategory (singer, instrumentalist, crew, dj)
    ProfessionalSubcategory? professionalSubcategory,

    /// Selected genres filter
    @Default([]) List<String> genres,

    /// Selected instruments filter (for instrumentalists)
    @Default([]) List<String> instruments,

    /// Selected crew roles filter (for crew)
    @Default([]) List<String> roles,

    /// Selected studio services filter (for studios)
    @Default([]) List<String> services,

    /// Filter for backing vocal capability
    /// null = don't filter, true = must do backing, false = solo only
    bool? canDoBackingVocal,

    /// Studio type filter (home_studio, commercial)
    String? studioType,
  }) = _SearchFilters;

  const SearchFilters._();

  /// Whether any filter is active (besides category)
  bool get hasActiveFilters =>
      term.isNotEmpty ||
      professionalSubcategory != null ||
      genres.isNotEmpty ||
      instruments.isNotEmpty ||
      roles.isNotEmpty ||
      services.isNotEmpty ||
      canDoBackingVocal != null ||
      studioType != null;

  /// Clears all filters except category
  SearchFilters clearFilters() => SearchFilters(category: category);

  /// Resets everything to default
  SearchFilters reset() => const SearchFilters();
}
