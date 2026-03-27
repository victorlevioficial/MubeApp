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

@ProviderFor(productionRoleLabels)
const productionRoleLabelsProvider = ProductionRoleLabelsProvider._();

final class ProductionRoleLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const ProductionRoleLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productionRoleLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productionRoleLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return productionRoleLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$productionRoleLabelsHash() =>
    r'bf2cfd1b59c6d2c0f97b7dfacad0be2fe99808d3';

@ProviderFor(stageTechRoleLabels)
const stageTechRoleLabelsProvider = StageTechRoleLabelsProvider._();

final class StageTechRoleLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const StageTechRoleLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stageTechRoleLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stageTechRoleLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return stageTechRoleLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$stageTechRoleLabelsHash() =>
    r'b5474f6d61fee1728c2e28da949a7cdc29c4d545';

@ProviderFor(audiovisualRoleLabels)
const audiovisualRoleLabelsProvider = AudiovisualRoleLabelsProvider._();

final class AudiovisualRoleLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const AudiovisualRoleLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audiovisualRoleLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audiovisualRoleLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return audiovisualRoleLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$audiovisualRoleLabelsHash() =>
    r'f328cad402ca9697be59f7a274124e9e9b774680';

@ProviderFor(educationRoleLabels)
const educationRoleLabelsProvider = EducationRoleLabelsProvider._();

final class EducationRoleLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const EducationRoleLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'educationRoleLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$educationRoleLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return educationRoleLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$educationRoleLabelsHash() =>
    r'd6b352720992dcaffc5d1af066d104bbb1bf9cfc';

@ProviderFor(luthierRoleLabels)
const luthierRoleLabelsProvider = LuthierRoleLabelsProvider._();

final class LuthierRoleLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const LuthierRoleLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'luthierRoleLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$luthierRoleLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return luthierRoleLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$luthierRoleLabelsHash() => r'79a2579162e003ad063eee6268e169d2467833d6';

@ProviderFor(performanceRoleLabels)
const performanceRoleLabelsProvider = PerformanceRoleLabelsProvider._();

final class PerformanceRoleLabelsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  const PerformanceRoleLabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'performanceRoleLabelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$performanceRoleLabelsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return performanceRoleLabels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$performanceRoleLabelsHash() =>
    r'e4bb01b1bc7dd67efba3c7d725f4df671a8ffc9f';

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
