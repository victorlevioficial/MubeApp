// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_gig_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateGigController)
const createGigControllerProvider = CreateGigControllerProvider._();

final class CreateGigControllerProvider
    extends $AsyncNotifierProvider<CreateGigController, void> {
  const CreateGigControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createGigControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createGigControllerHash();

  @$internal
  @override
  CreateGigController create() => CreateGigController();
}

String _$createGigControllerHash() =>
    r'78a7b621ae7e1f652b1d3f5b050048c1cefc65ae';

abstract class _$CreateGigController extends $AsyncNotifier<void> {
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
