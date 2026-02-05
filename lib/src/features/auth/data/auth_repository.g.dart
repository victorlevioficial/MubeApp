// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
const authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  const AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'699815b2710e684ad1c2c02f2bb9975b4b6e50cb';

/// Stream provider for Firebase Auth state changes.

@ProviderFor(authStateChanges)
const authStateChangesProvider = AuthStateChangesProvider._();

/// Stream provider for Firebase Auth state changes.

final class AuthStateChangesProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Stream provider for Firebase Auth state changes.
  const AuthStateChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateChangesHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authStateChanges(ref);
  }
}

String _$authStateChangesHash() => r'346b4034b145750aef0a6f0135919eb8e0c35d34';

/// Stream provider for the current user's profile data from Firestore.
///
/// Returns `null` if the user is not authenticated or profile doesn't exist.

@ProviderFor(currentUserProfile)
const currentUserProfileProvider = CurrentUserProfileProvider._();

/// Stream provider for the current user's profile data from Firestore.
///
/// Returns `null` if the user is not authenticated or profile doesn't exist.

final class CurrentUserProfileProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  /// Stream provider for the current user's profile data from Firestore.
  ///
  /// Returns `null` if the user is not authenticated or profile doesn't exist.
  const CurrentUserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return currentUserProfile(ref);
  }
}

String _$currentUserProfileHash() =>
    r'f82f3eb2c38b3fcbd7e062275f3b2e40527ce8d7';

@ProviderFor(membersList)
const membersListProvider = MembersListFamily._();

final class MembersListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          FutureOr<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $FutureProvider<List<AppUser>> {
  const MembersListProvider._({
    required MembersListFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'membersListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$membersListHash();

  @override
  String toString() {
    return r'membersListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppUser>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return membersList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MembersListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$membersListHash() => r'ba75a7089b833f08a9c5b05f467168d85169a104';

final class MembersListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AppUser>>, List<String>> {
  const MembersListFamily._()
    : super(
        retry: null,
        name: r'membersListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MembersListProvider call(List<String> uids) =>
      MembersListProvider._(argument: uids, from: this);

  @override
  String toString() => r'membersListProvider';
}
