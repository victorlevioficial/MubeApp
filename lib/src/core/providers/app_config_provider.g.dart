// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider que carrega e disponibiliza as configurações do app

@ProviderFor(appConfig)
const appConfigProvider = AppConfigProvider._();

/// Provider que carrega e disponibiliza as configurações do app

final class AppConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppConfig>,
          AppConfig,
          FutureOr<AppConfig>
        >
    with $FutureModifier<AppConfig>, $FutureProvider<AppConfig> {
  /// Provider que carrega e disponibiliza as configurações do app
  const AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $FutureProviderElement<AppConfig> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AppConfig> create(Ref ref) {
    return appConfig(ref);
  }
}

String _$appConfigHash() => r'c8de00e13cd115987b6389d3fe6ede99f314e904';

/// Helpers para acesso direto às listas (retorna labels como strings para compatibilidade)

@ProviderFor(genreLabels)
const genreLabelsProvider = GenreLabelsProvider._();

/// Helpers para acesso direto às listas (retorna labels como strings para compatibilidade)

final class GenreLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// Helpers para acesso direto às listas (retorna labels como strings para compatibilidade)
  const GenreLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'genreLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$genreLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return genreLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$genreLabelsHash() => r'3fb01e44ad9e2cf8dbc56e042f36e5c0d7d58b3c';

@ProviderFor(instrumentLabels)
const instrumentLabelsProvider = InstrumentLabelsProvider._();

final class InstrumentLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const InstrumentLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'instrumentLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$instrumentLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return instrumentLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$instrumentLabelsHash() => r'efd17e9f57bb28b057531bce821d0481f711df58';

@ProviderFor(crewRoleLabels)
const crewRoleLabelsProvider = CrewRoleLabelsProvider._();

final class CrewRoleLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const CrewRoleLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crewRoleLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crewRoleLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return crewRoleLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$crewRoleLabelsHash() => r'5b17c10047853267357935dec90f87b3219371c7';

@ProviderFor(studioServiceLabels)
const studioServiceLabelsProvider = StudioServiceLabelsProvider._();

final class StudioServiceLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const StudioServiceLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studioServiceLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studioServiceLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return studioServiceLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$studioServiceLabelsHash() =>
    r'1ca7f7233361d87b1a8ff0da79b7538f55df3d89';

/// Helper para matching inteligente (verifica aliases)

@ProviderFor(canMatch)
const canMatchProvider = CanMatchFamily._();

/// Helper para matching inteligente (verifica aliases)

final class CanMatchProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Helper para matching inteligente (verifica aliases)
  const CanMatchProvider._({
    required CanMatchFamily super.from,
    required ({String userTag, String targetTag, String type}) super.argument,
  }) : super(
         retry: null,
         name: r'canMatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canMatchHash();

  @override
  String toString() {
    return r'canMatchProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument =
        this.argument as ({String userTag, String targetTag, String type});
    return canMatch(
      ref,
      userTag: argument.userTag,
      targetTag: argument.targetTag,
      type: argument.type,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CanMatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canMatchHash() => r'aad87750af60bf703dadaf5ad290f372401b764f';

/// Helper para matching inteligente (verifica aliases)

final class CanMatchFamily extends $Family
    with
        $FunctionalFamilyOverride<
          bool,
          ({String userTag, String targetTag, String type})
        > {
  const CanMatchFamily._()
    : super(
        retry: null,
        name: r'canMatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Helper para matching inteligente (verifica aliases)

  CanMatchProvider call({
    required String userTag,
    required String targetTag,
    required String type,
  }) => CanMatchProvider._(
    argument: (userTag: userTag, targetTag: targetTag, type: type),
    from: this,
  );

  @override
  String toString() => r'canMatchProvider';
}
