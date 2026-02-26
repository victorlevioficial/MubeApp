// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_profiles_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository para ler perfis em destaque configurados pelo admin.
///
/// Lê o documento `config/featuredProfiles` no Firestore, que contém
/// uma lista de UIDs definidos manualmente pelo painel admin.

@ProviderFor(featuredProfilesRepository)
const featuredProfilesRepositoryProvider =
    FeaturedProfilesRepositoryProvider._();

/// Repository para ler perfis em destaque configurados pelo admin.
///
/// Lê o documento `config/featuredProfiles` no Firestore, que contém
/// uma lista de UIDs definidos manualmente pelo painel admin.

final class FeaturedProfilesRepositoryProvider
    extends
        $FunctionalProvider<
          FeaturedProfilesRepository,
          FeaturedProfilesRepository,
          FeaturedProfilesRepository
        >
    with $Provider<FeaturedProfilesRepository> {
  /// Repository para ler perfis em destaque configurados pelo admin.
  ///
  /// Lê o documento `config/featuredProfiles` no Firestore, que contém
  /// uma lista de UIDs definidos manualmente pelo painel admin.
  const FeaturedProfilesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featuredProfilesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featuredProfilesRepositoryHash();

  @$internal
  @override
  $ProviderElement<FeaturedProfilesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeaturedProfilesRepository create(Ref ref) {
    return featuredProfilesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeaturedProfilesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeaturedProfilesRepository>(value),
    );
  }
}

String _$featuredProfilesRepositoryHash() =>
    r'fcf6c51c2c4415cec8290a0ba3b28ed7a639f791';
