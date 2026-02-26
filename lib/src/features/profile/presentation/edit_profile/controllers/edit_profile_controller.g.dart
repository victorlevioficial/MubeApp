// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EditProfileController)
const editProfileControllerProvider = EditProfileControllerFamily._();

final class EditProfileControllerProvider
    extends $NotifierProvider<EditProfileController, EditProfileState> {
  const EditProfileControllerProvider._({
    required EditProfileControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'editProfileControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$editProfileControllerHash();

  @override
  String toString() {
    return r'editProfileControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EditProfileController create() => EditProfileController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditProfileState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditProfileState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EditProfileControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$editProfileControllerHash() =>
    r'fa37331ec48f6210ba64714fc86fe2270bb4479b';

final class EditProfileControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EditProfileController,
          EditProfileState,
          EditProfileState,
          EditProfileState,
          String
        > {
  const EditProfileControllerFamily._()
    : super(
        retry: null,
        name: r'editProfileControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EditProfileControllerProvider call(String userId) =>
      EditProfileControllerProvider._(argument: userId, from: this);

  @override
  String toString() => r'editProfileControllerProvider';
}

abstract class _$EditProfileController extends $Notifier<EditProfileState> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  EditProfileState build(String userId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<EditProfileState, EditProfileState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EditProfileState, EditProfileState>,
              EditProfileState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
