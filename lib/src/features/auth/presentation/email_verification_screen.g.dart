// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_verification_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EmailVerificationController)
const emailVerificationControllerProvider =
    EmailVerificationControllerProvider._();

final class EmailVerificationControllerProvider
    extends
        $NotifierProvider<EmailVerificationController, EmailVerificationState> {
  const EmailVerificationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emailVerificationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emailVerificationControllerHash();

  @$internal
  @override
  EmailVerificationController create() => EmailVerificationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmailVerificationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmailVerificationState>(value),
    );
  }
}

String _$emailVerificationControllerHash() =>
    r'cdc8973ad54459c157a2b0a64d715af3e13e5141';

abstract class _$EmailVerificationController
    extends $Notifier<EmailVerificationState> {
  EmailVerificationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<EmailVerificationState, EmailVerificationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EmailVerificationState, EmailVerificationState>,
              EmailVerificationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
