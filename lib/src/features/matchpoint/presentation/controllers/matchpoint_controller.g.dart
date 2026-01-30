// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchpoint_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MatchpointController)
const matchpointControllerProvider = MatchpointControllerProvider._();

final class MatchpointControllerProvider
    extends $AsyncNotifierProvider<MatchpointController, void> {
  const MatchpointControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchpointControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchpointControllerHash();

  @$internal
  @override
  MatchpointController create() => MatchpointController();
}

String _$matchpointControllerHash() =>
    r'd5919d5c0262ad4aa6ecf8dafe692f3b64f0a4d5';

abstract class _$MatchpointController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

@ProviderFor(matchpointCandidates)
const matchpointCandidatesProvider = MatchpointCandidatesProvider._();

final class MatchpointCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          FutureOr<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $FutureProvider<List<AppUser>> {
  const MatchpointCandidatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchpointCandidatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchpointCandidatesHash();

  @$internal
  @override
  $FutureProviderElement<List<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppUser>> create(Ref ref) {
    return matchpointCandidates(ref);
  }
}

String _$matchpointCandidatesHash() =>
    r'5b5012452fa2836607c93e79cfc093edd79e0b9e';
