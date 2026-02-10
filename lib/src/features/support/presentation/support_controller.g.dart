// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SupportController)
const supportControllerProvider = SupportControllerProvider._();

final class SupportControllerProvider
    extends $AsyncNotifierProvider<SupportController, void> {
  const SupportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportControllerHash();

  @$internal
  @override
  SupportController create() => SupportController();
}

String _$supportControllerHash() => r'22c95bab1747f078516685a5e0664dc10133d958';

abstract class _$SupportController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

@ProviderFor(userTickets)
const userTicketsProvider = UserTicketsProvider._();

final class UserTicketsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ticket>>,
          List<Ticket>,
          Stream<List<Ticket>>
        >
    with $FutureModifier<List<Ticket>>, $StreamProvider<List<Ticket>> {
  const UserTicketsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userTicketsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userTicketsHash();

  @$internal
  @override
  $StreamProviderElement<List<Ticket>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Ticket>> create(Ref ref) {
    return userTickets(ref);
  }
}

String _$userTicketsHash() => r'828d95a99fe27fe42becc515ab7d83bfeb530d10';
