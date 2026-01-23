// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_favorite_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(feedFavoriteService)
const feedFavoriteServiceProvider = FeedFavoriteServiceProvider._();

final class FeedFavoriteServiceProvider
    extends
        $FunctionalProvider<
          FeedFavoriteService,
          FeedFavoriteService,
          FeedFavoriteService
        >
    with $Provider<FeedFavoriteService> {
  const FeedFavoriteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedFavoriteServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedFavoriteServiceHash();

  @$internal
  @override
  $ProviderElement<FeedFavoriteService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeedFavoriteService create(Ref ref) {
    return feedFavoriteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedFavoriteService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedFavoriteService>(value),
    );
  }
}

String _$feedFavoriteServiceHash() =>
    r'18e29f1cb5928a521b587d515affd25ef8140d9d';

/// Provider family para verificar se um item é favorito.

@ProviderFor(isFavorited)
const isFavoritedProvider = IsFavoritedFamily._();

/// Provider family para verificar se um item é favorito.

final class IsFavoritedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Provider family para verificar se um item é favorito.
  const IsFavoritedProvider._({
    required IsFavoritedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isFavoritedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFavoritedHash();

  @override
  String toString() {
    return r'isFavoritedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isFavorited(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsFavoritedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFavoritedHash() => r'4f95ff1468a476206575e85404fdcece2aecfe4c';

/// Provider family para verificar se um item é favorito.

final class IsFavoritedFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, String> {
  const IsFavoritedFamily._()
    : super(
        retry: null,
        name: r'isFavoritedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider family para verificar se um item é favorito.

  IsFavoritedProvider call(String targetId) =>
      IsFavoritedProvider._(argument: targetId, from: this);

  @override
  String toString() => r'isFavoritedProvider';
}

/// Provider family para observar a contagem de favoritos de um item.

@ProviderFor(favoriteCount)
const favoriteCountProvider = FavoriteCountFamily._();

/// Provider family para observar a contagem de favoritos de um item.

final class FavoriteCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Provider family para observar a contagem de favoritos de um item.
  const FavoriteCountProvider._({
    required FavoriteCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'favoriteCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$favoriteCountHash();

  @override
  String toString() {
    return r'favoriteCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return favoriteCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FavoriteCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$favoriteCountHash() => r'401620c8416cba160db034bd926c640c56da25c2';

/// Provider family para observar a contagem de favoritos de um item.

final class FavoriteCountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  const FavoriteCountFamily._()
    : super(
        retry: null,
        name: r'favoriteCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider family para observar a contagem de favoritos de um item.

  FavoriteCountProvider call(String targetId) =>
      FavoriteCountProvider._(argument: targetId, from: this);

  @override
  String toString() => r'favoriteCountProvider';
}
