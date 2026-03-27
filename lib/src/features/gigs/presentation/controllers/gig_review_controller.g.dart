// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gig_review_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GigReviewController)
const gigReviewControllerProvider = GigReviewControllerProvider._();

final class GigReviewControllerProvider
    extends $AsyncNotifierProvider<GigReviewController, void> {
  const GigReviewControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gigReviewControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gigReviewControllerHash();

  @$internal
  @override
  GigReviewController create() => GigReviewController();
}

String _$gigReviewControllerHash() =>
    r'162e3d97650a9d51c9c337a06ac596c3c3431d42';

abstract class _$GigReviewController extends $AsyncNotifier<void> {
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
