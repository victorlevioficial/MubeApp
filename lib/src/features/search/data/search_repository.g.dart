// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [SearchRepository] instance.

@ProviderFor(searchRepository)
const searchRepositoryProvider = SearchRepositoryProvider._();

/// Provides a [SearchRepository] instance.

final class SearchRepositoryProvider
    extends
        $FunctionalProvider<
          SearchRepository,
          SearchRepository,
          SearchRepository
        >
    with $Provider<SearchRepository> {
  /// Provides a [SearchRepository] instance.
  const SearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchRepositoryHash();

  @$internal
  @override
  $ProviderElement<SearchRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchRepository create(Ref ref) {
    return searchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchRepository>(value),
    );
  }
}

String _$searchRepositoryHash() => r'3a2302946dd242289b7cf5ca1eefde4a15388291';

/// Current search filters state.

@ProviderFor(SearchFiltersNotifier)
const searchFiltersProvider = SearchFiltersNotifierProvider._();

/// Current search filters state.
final class SearchFiltersNotifierProvider
    extends $NotifierProvider<SearchFiltersNotifier, SearchFilters> {
  /// Current search filters state.
  const SearchFiltersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchFiltersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchFiltersNotifierHash();

  @$internal
  @override
  SearchFiltersNotifier create() => SearchFiltersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchFilters value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchFilters>(value),
    );
  }
}

String _$searchFiltersNotifierHash() =>
    r'68e6b7376a6e95b2f8e5ec31cb6a0a0d4ff8650c';

/// Current search filters state.

abstract class _$SearchFiltersNotifier extends $Notifier<SearchFilters> {
  SearchFilters build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SearchFilters, SearchFilters>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchFilters, SearchFilters>,
              SearchFilters,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provides search results based on current filters.

@ProviderFor(searchResults)
const searchResultsProvider = SearchResultsProvider._();

/// Provides search results based on current filters.

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          FutureOr<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $FutureProvider<List<AppUser>> {
  /// Provides search results based on current filters.
  const SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppUser>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'73b271ce1f0d3de9e74ec9da5fca0c90931148a0';
