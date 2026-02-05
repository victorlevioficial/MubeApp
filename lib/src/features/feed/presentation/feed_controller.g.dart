// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeedController)
const feedControllerProvider = FeedControllerProvider._();

final class FeedControllerProvider
    extends $AsyncNotifierProvider<FeedController, FeedState> {
  const FeedControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedControllerHash();

  @$internal
  @override
  FeedController create() => FeedController();
}

String _$feedControllerHash() => r'e0bb28855d8295fa46faf37f8cc14198e9433438';

abstract class _$FeedController extends $AsyncNotifier<FeedState> {
  FutureOr<FeedState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<FeedState>, FeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FeedState>, FeedState>,
              AsyncValue<FeedState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
