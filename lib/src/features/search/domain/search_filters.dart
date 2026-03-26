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

  /// Public venues/contractors
  venues,
}

/// Professional subcategories (only applies when category is [SearchCategory.professionals])
enum ProfessionalSubcategory {
  singer('singer'),
  instrumentalist('instrumentalist'),
  production('production'),
  stageTech('stage_tech'),
  dj('dj');

  const ProfessionalSubcategory(this.firestoreId);

  final String firestoreId;
}

/// Represents the current search filter state.
@freezed
abstract class SearchFilters with _$SearchFilters {
  const factory SearchFilters({
    /// Text search term (normalized)
    @Default('') String term,

    /// Main category filter
    @Default(SearchCategory.all) SearchCategory category,

    /// Professional subcategory (singer, instrumentalist, production, stageTech, dj)
    ProfessionalSubcategory? professionalSubcategory,

    /// Selected genres filter
    @Default([]) List<String> genres,

    /// Selected instruments filter (for instrumentalists)
    @Default([]) List<String> instruments,

    /// Selected professional role filters (production/stage tech)
    @Default([]) List<String> roles,

    /// Only include production profiles that offer remote recording
    bool? offersRemoteRecording,

    /// Selected studio services filter (for studios)
    @Default([]) List<String> services,

    /// Filter for backing vocal capability
    /// null = don't filter, true = must do backing, false = solo only
    bool? canDoBackingVocal,

    /// Studio type filter (home_studio, commercial)
    String? studioType,
  }) = _SearchFilters;

  const SearchFilters._();

  /// Whether the current filters require professional profiles.
  bool get hasProfessionalOnlyFilters =>
      professionalSubcategory != null ||
      instruments.isNotEmpty ||
      roles.isNotEmpty ||
      canDoBackingVocal != null ||
      offersRemoteRecording == true;

  /// Whether the current filters require studio profiles.
  bool get hasStudioOnlyFilters => services.isNotEmpty || studioType != null;

  /// Whether the current filter combination cannot match any profile type.
  bool get hasConflictingTypeFilters {
    switch (category) {
      case SearchCategory.all:
        return hasProfessionalOnlyFilters && hasStudioOnlyFilters;
      case SearchCategory.professionals:
        return hasStudioOnlyFilters;
      case SearchCategory.studios:
        return hasProfessionalOnlyFilters;
      case SearchCategory.venues:
        return hasProfessionalOnlyFilters;
      case SearchCategory.bands:
        return hasProfessionalOnlyFilters || hasStudioOnlyFilters;
    }
  }

  /// Removes filters that do not make sense for the selected category.
  SearchFilters sanitizeForCategory(SearchCategory nextCategory) {
    var next = copyWith(category: nextCategory);

    final isCurrentStudioLike =
        category == SearchCategory.studios || category == SearchCategory.venues;
    final isNextStudioLike =
        nextCategory == SearchCategory.studios ||
        nextCategory == SearchCategory.venues;

    if (isCurrentStudioLike &&
        isNextStudioLike &&
        category != nextCategory) {
      next = next.copyWith(services: const [], studioType: null);
    }

    if (category == SearchCategory.venues &&
        nextCategory != SearchCategory.venues) {
      next = next.copyWith(services: const [], studioType: null);
    }

    if (nextCategory == SearchCategory.professionals ||
        nextCategory == SearchCategory.bands) {
      next = next.copyWith(services: const [], studioType: null);
    }

    if (nextCategory == SearchCategory.studios ||
        nextCategory == SearchCategory.venues ||
        nextCategory == SearchCategory.bands) {
      next = next.copyWith(
        professionalSubcategory: null,
        instruments: const [],
        roles: const [],
        canDoBackingVocal: null,
        offersRemoteRecording: null,
      );
    }

    if (nextCategory == SearchCategory.venues) {
      next = next.copyWith(genres: const []);
    }

    return next;
  }

  /// Removes production-only filters when the professional subcategory changes.
  SearchFilters sanitizeForProfessionalSubcategory(
    ProfessionalSubcategory? nextSubcategory,
  ) {
    var next = copyWith(professionalSubcategory: nextSubcategory);

    if (nextSubcategory != ProfessionalSubcategory.production) {
      next = next.copyWith(offersRemoteRecording: null);
    }

    return next;
  }

  /// Sanitizes filters before executing a search.
  SearchFilters sanitizedForSearch() {
    switch (category) {
      case SearchCategory.all:
        return this;
      case SearchCategory.professionals:
      case SearchCategory.studios:
      case SearchCategory.venues:
      case SearchCategory.bands:
        return sanitizeForCategory(category);
    }
  }

  /// Whether any filter is active (besides category)
  bool get hasActiveFilters =>
      term.isNotEmpty ||
      professionalSubcategory != null ||
      genres.isNotEmpty ||
      instruments.isNotEmpty ||
      roles.isNotEmpty ||
      services.isNotEmpty ||
      canDoBackingVocal != null ||
      offersRemoteRecording == true ||
      studioType != null;

  /// Clears all filters except category
  SearchFilters clearFilters() => SearchFilters(category: category);

  /// Resets everything to default
  SearchFilters reset() => const SearchFilters();
}
