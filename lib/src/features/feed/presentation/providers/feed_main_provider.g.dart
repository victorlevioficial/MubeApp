// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_main_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider que gerencia o feed principal com paginação determinística.
///
/// Substitui o antigo `FeedMainController` + `FeedMainRuntime` por um
/// Notifier Riverpod gerenciado, permitindo testes e reuso sem
/// instanciação manual.

@ProviderFor(FeedMain)
const feedMainProvider = FeedMainProvider._();

/// Provider que gerencia o feed principal com paginação determinística.
///
/// Substitui o antigo `FeedMainController` + `FeedMainRuntime` por um
/// Notifier Riverpod gerenciado, permitindo testes e reuso sem
/// instanciação manual.
final class FeedMainProvider extends $NotifierProvider<FeedMain, FeedState> {
  /// Provider que gerencia o feed principal com paginação determinística.
  ///
  /// Substitui o antigo `FeedMainController` + `FeedMainRuntime` por um
  /// Notifier Riverpod gerenciado, permitindo testes e reuso sem
  /// instanciação manual.
  const FeedMainProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedMainProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedMainHash();

  @$internal
  @override
  FeedMain create() => FeedMain();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedState>(value),
    );
  }
}

String _$feedMainHash() => r'bdedeb0303fc5b1a83ff8050adcdbe208af30b2b';

/// Provider que gerencia o feed principal com paginação determinística.
///
/// Substitui o antigo `FeedMainController` + `FeedMainRuntime` por um
/// Notifier Riverpod gerenciado, permitindo testes e reuso sem
/// instanciação manual.

abstract class _$FeedMain extends $Notifier<FeedState> {
  FeedState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<FeedState, FeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FeedState, FeedState>,
              FeedState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
