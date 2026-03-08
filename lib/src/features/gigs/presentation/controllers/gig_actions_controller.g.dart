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
        isAutoDispose: true,
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
    r'9397f7f656fd6b7160fb41ba7df5634309158943';

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
