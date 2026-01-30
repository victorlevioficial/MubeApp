// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchpoint_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(matchpointRepository)
const matchpointRepositoryProvider = MatchpointRepositoryProvider._();

final class MatchpointRepositoryProvider
    extends
        $FunctionalProvider<
          MatchpointRepository,
          MatchpointRepository,
          MatchpointRepository
        >
    with $Provider<MatchpointRepository> {
  const MatchpointRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchpointRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchpointRepositoryHash();

  @$internal
  @override
  $ProviderElement<MatchpointRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MatchpointRepository create(Ref ref) {
    return matchpointRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatchpointRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatchpointRepository>(value),
    );
  }
}

String _$matchpointRepositoryHash() =>
    r'1abe7245cfff87ed5066dce48901a8107048f44a';
