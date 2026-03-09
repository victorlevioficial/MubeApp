// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supportRepository)
const supportRepositoryProvider = SupportRepositoryProvider._();

final class SupportRepositoryProvider
    extends
        $FunctionalProvider<
          SupportRepository,
          SupportRepository,
          SupportRepository
        >
    with $Provider<SupportRepository> {
  const SupportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupportRepository create(Ref ref) {
    return supportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupportRepository>(value),
    );
  }
}

String _$supportRepositoryHash() => r'969e13514e0d6590d10b1955beb6debab96a418e';
