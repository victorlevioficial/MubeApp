// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invites_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(invitesRepository)
const invitesRepositoryProvider = InvitesRepositoryProvider._();

final class InvitesRepositoryProvider
    extends
        $FunctionalProvider<
          InvitesRepository,
          InvitesRepository,
          InvitesRepository
        >
    with $Provider<InvitesRepository> {
  const InvitesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invitesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invitesRepositoryHash();

  @$internal
  @override
  $ProviderElement<InvitesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InvitesRepository create(Ref ref) {
    return invitesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvitesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvitesRepository>(value),
    );
  }
}

String _$invitesRepositoryHash() => r'7e1d074852cdd3ce8495bbe46ee5cefd1a8f952c';

@ProviderFor(pendingInviteCount)
const pendingInviteCountProvider = PendingInviteCountFamily._();

final class PendingInviteCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  const PendingInviteCountProvider._({
    required PendingInviteCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingInviteCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingInviteCountHash();

  @override
  String toString() {
    return r'pendingInviteCountProvider'
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
    return pendingInviteCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingInviteCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingInviteCountHash() =>
    r'2c69cd1be285239e478064c3c20023b356f010a0';

final class PendingInviteCountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  const PendingInviteCountFamily._()
    : super(
        retry: null,
        name: r'pendingInviteCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PendingInviteCountProvider call(String uid) =>
      PendingInviteCountProvider._(argument: uid, from: this);

  @override
  String toString() => r'pendingInviteCountProvider';
}
