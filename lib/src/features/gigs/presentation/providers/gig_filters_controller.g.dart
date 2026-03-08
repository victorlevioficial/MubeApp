// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gig_filters_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GigFiltersController)
const gigFiltersControllerProvider = GigFiltersControllerProvider._();

final class GigFiltersControllerProvider
    extends $NotifierProvider<GigFiltersController, GigFilters> {
  const GigFiltersControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gigFiltersControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gigFiltersControllerHash();

  @$internal
  @override
  GigFiltersController create() => GigFiltersController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GigFilters value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GigFilters>(value),
    );
  }
}

String _$gigFiltersControllerHash() =>
    r'7db0a6ebd04aaea33a43f1cfa93f921be227ed58';

abstract class _$GigFiltersController extends $Notifier<GigFilters> {
  GigFilters build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<GigFilters, GigFilters>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GigFilters, GigFilters>,
              GigFilters,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
