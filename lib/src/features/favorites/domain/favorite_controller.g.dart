// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FavoriteController)
const favoriteControllerProvider = FavoriteControllerProvider._();

final class FavoriteControllerProvider
    extends $NotifierProvider<FavoriteController, FavoriteState> {
  const FavoriteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteControllerHash();

  @$internal
  @override
  FavoriteController create() => FavoriteController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteState>(value),
    );
  }
}

String _$favoriteControllerHash() =>
    r'6cf495c4377934a21a4bfd7e5ed54672a7faa4a5';

abstract class _$FavoriteController extends $Notifier<FavoriteState> {
  FavoriteState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<FavoriteState, FavoriteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FavoriteState, FavoriteState>,
              FavoriteState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
