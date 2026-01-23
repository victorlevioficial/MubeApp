// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PublicProfileController)
const publicProfileControllerProvider = PublicProfileControllerFamily._();

final class PublicProfileControllerProvider
    extends
        $AsyncNotifierProvider<PublicProfileController, PublicProfileState> {
  const PublicProfileControllerProvider._({
    required PublicProfileControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'publicProfileControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publicProfileControllerHash();

  @override
  String toString() {
    return r'publicProfileControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PublicProfileController create() => PublicProfileController();

  @override
  bool operator ==(Object other) {
    return other is PublicProfileControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicProfileControllerHash() =>
    r'35d3185aee40d4ec2eb2a25919d482c8bc52c79b';

final class PublicProfileControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PublicProfileController,
          AsyncValue<PublicProfileState>,
          PublicProfileState,
          FutureOr<PublicProfileState>,
          String
        > {
  const PublicProfileControllerFamily._()
    : super(
        retry: null,
        name: r'publicProfileControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PublicProfileControllerProvider call(String uid) =>
      PublicProfileControllerProvider._(argument: uid, from: this);

  @override
  String toString() => r'publicProfileControllerProvider';
}

abstract class _$PublicProfileController
    extends $AsyncNotifier<PublicProfileState> {
  late final _$args = ref.$arg as String;
  String get uid => _$args;

  FutureOr<PublicProfileState> build(String uid);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<PublicProfileState>, PublicProfileState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PublicProfileState>, PublicProfileState>,
              AsyncValue<PublicProfileState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
