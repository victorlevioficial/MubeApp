// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_profiles_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider que carrega os perfis em destaque do admin.
///
/// Substitui o antigo `FeaturedProfilesController` por um provider Riverpod
/// gerenciado, permitindo testes e reuso sem instanciacao manual.

@ProviderFor(featuredProfiles)
const featuredProfilesProvider = FeaturedProfilesProvider._();

/// Provider que carrega os perfis em destaque do admin.
///
/// Substitui o antigo `FeaturedProfilesController` por um provider Riverpod
/// gerenciado, permitindo testes e reuso sem instanciacao manual.

final class FeaturedProfilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FeedItem>>,
          List<FeedItem>,
          FutureOr<List<FeedItem>>
        >
    with $FutureModifier<List<FeedItem>>, $FutureProvider<List<FeedItem>> {
  /// Provider que carrega os perfis em destaque do admin.
  ///
  /// Substitui o antigo `FeaturedProfilesController` por um provider Riverpod
  /// gerenciado, permitindo testes e reuso sem instanciacao manual.
  const FeaturedProfilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featuredProfilesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featuredProfilesHash();

  @$internal
  @override
  $FutureProviderElement<List<FeedItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FeedItem>> create(Ref ref) {
    return featuredProfiles(ref);
  }
}

String _$featuredProfilesHash() => r'7652f31db295944ad17b4fe718f41d27fc069940';
