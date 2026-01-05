import 'package:freezed_annotation/freezed_annotation.dart';
import '../../auth/domain/user_type.dart';

part 'search_filters.freezed.dart';
part 'search_filters.g.dart';

/// Filters for user search queries.
///
/// All filters are optional and can be combined.
@freezed
abstract class SearchFilters with _$SearchFilters {
  const factory SearchFilters({
    /// Free-text search query (matches name, artistic name).
    String? query,

    /// Filter by profile type.
    AppUserType? type,

    /// Filter by city name.
    String? city,

    /// Filter by state code (e.g., 'SP', 'RJ').
    String? state,

    /// Filter by musical genres.
    @Default([]) List<String> genres,

    /// Maximum distance in km (requires user location).
    double? maxDistance,
  }) = _SearchFilters;

  const SearchFilters._();

  /// Whether any filter is active.
  bool get hasActiveFilters =>
      query != null && query!.isNotEmpty ||
      type != null ||
      city != null ||
      state != null ||
      genres.isNotEmpty;

  factory SearchFilters.fromJson(Map<String, dynamic> json) =>
      _$SearchFiltersFromJson(json);
}
