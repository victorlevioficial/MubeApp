// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gig_actions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GigActionsController)
const gigActionsControllerProvider = GigActionsControllerProvider._();

final class GigActionsControllerProvider
    extends $AsyncNotifierProvider<GigActionsController, void> {
  const GigActionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gigActionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gigActionsControllerHash();

  @$internal
  @override
  GigActionsController create() => GigActionsController();
}

String _$gigActionsControllerHash() =>
    r'f4ea9fe33e0f3d408259f24da6ef150638d90576';

abstract class _$GigActionsController extends $AsyncNotifier<void> {
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
