// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_seeder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appSeeder)
const appSeederProvider = AppSeederProvider._();

final class AppSeederProvider
    extends $FunctionalProvider<AppSeeder, AppSeeder, AppSeeder>
    with $Provider<AppSeeder> {
  const AppSeederProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSeederProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSeederHash();

  @$internal
  @override
  $ProviderElement<AppSeeder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppSeeder create(Ref ref) {
    return appSeeder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSeeder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSeeder>(value),
    );
  }
}

String _$appSeederHash() => r'41c096626a7d849f87be7892d4e40c5faeafc91e';
