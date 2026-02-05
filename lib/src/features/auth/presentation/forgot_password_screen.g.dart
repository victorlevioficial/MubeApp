// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ForgotPasswordController)
const forgotPasswordControllerProvider = ForgotPasswordControllerProvider._();

final class ForgotPasswordControllerProvider
    extends $AsyncNotifierProvider<ForgotPasswordController, void> {
  const ForgotPasswordControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forgotPasswordControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forgotPasswordControllerHash();

  @$internal
  @override
  ForgotPasswordController create() => ForgotPasswordController();
}

String _$forgotPasswordControllerHash() =>
    r'6fdf70b0c317ae3d39f5e2cbfc07d776901e90ad';

abstract class _$ForgotPasswordController extends $AsyncNotifier<void> {
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
