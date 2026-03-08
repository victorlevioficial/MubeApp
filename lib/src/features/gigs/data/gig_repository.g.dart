// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gig_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gigRepository)
const gigRepositoryProvider = GigRepositoryProvider._();

final class GigRepositoryProvider
    extends $FunctionalProvider<GigRepository, GigRepository, GigRepository>
    with $Provider<GigRepository> {
  const GigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gigRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gigRepositoryHash();

  @$internal
  @override
  $ProviderElement<GigRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GigRepository create(Ref ref) {
    return gigRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GigRepository>(value),
    );
  }
}

String _$gigRepositoryHash() => r'08911bdbfd3619dd1d60b9b863926d455ff784a1';
