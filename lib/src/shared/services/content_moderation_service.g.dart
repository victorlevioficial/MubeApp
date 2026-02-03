// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_moderation_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contentModerationService)
const contentModerationServiceProvider = ContentModerationServiceProvider._();

final class ContentModerationServiceProvider
    extends
        $FunctionalProvider<
          ContentModerationService,
          ContentModerationService,
          ContentModerationService
        >
    with $Provider<ContentModerationService> {
  const ContentModerationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentModerationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentModerationServiceHash();

  @$internal
  @override
  $ProviderElement<ContentModerationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentModerationService create(Ref ref) {
    return contentModerationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentModerationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentModerationService>(value),
    );
  }
}

String _$contentModerationServiceHash() =>
    r'5f6dea254f6d4d493c3894a73440903e839aed46';
