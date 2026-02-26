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
    r'a6c80f5a895f65b7fbe08ee7cc1a319e99d8df9a';

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
