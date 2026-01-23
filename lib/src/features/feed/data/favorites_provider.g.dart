// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ============================================================================
/// SISTEMA DE LIKES - ARQUITETURA PROFISSIONAL
/// ============================================================================
///
/// Estrutura no Firestore:
///
/// likes/{likeId}
///   ├── fromUserId: String (quem deu o like)
///   ├── toUserId: String (quem recebeu o like)
///   └── createdAt: Timestamp
///
/// Onde likeId = "${fromUserId}_${toUserId}" (garante unicidade/idempotência)
///
/// users/{userId}
///   └── favoriteCount: int (atualizado atomicamente via transação)
///
/// ============================================================================
/// Controller para gerenciar likes do usuário logado.
///
/// Usa documentos individuais na coleção `likes/` com ID composto,
/// garantindo operações idempotentes e sem duplicação.

@ProviderFor(LikesController)
const likesControllerProvider = LikesControllerProvider._();

/// ============================================================================
/// SISTEMA DE LIKES - ARQUITETURA PROFISSIONAL
/// ============================================================================
///
/// Estrutura no Firestore:
///
/// likes/{likeId}
///   ├── fromUserId: String (quem deu o like)
///   ├── toUserId: String (quem recebeu o like)
///   └── createdAt: Timestamp
///
/// Onde likeId = "${fromUserId}_${toUserId}" (garante unicidade/idempotência)
///
/// users/{userId}
///   └── favoriteCount: int (atualizado atomicamente via transação)
///
/// ============================================================================
/// Controller para gerenciar likes do usuário logado.
///
/// Usa documentos individuais na coleção `likes/` com ID composto,
/// garantindo operações idempotentes e sem duplicação.
final class LikesControllerProvider
    extends $AsyncNotifierProvider<LikesController, Set<String>> {
  /// ============================================================================
  /// SISTEMA DE LIKES - ARQUITETURA PROFISSIONAL
  /// ============================================================================
  ///
  /// Estrutura no Firestore:
  ///
  /// likes/{likeId}
  ///   ├── fromUserId: String (quem deu o like)
  ///   ├── toUserId: String (quem recebeu o like)
  ///   └── createdAt: Timestamp
  ///
  /// Onde likeId = "${fromUserId}_${toUserId}" (garante unicidade/idempotência)
  ///
  /// users/{userId}
  ///   └── favoriteCount: int (atualizado atomicamente via transação)
  ///
  /// ============================================================================
  /// Controller para gerenciar likes do usuário logado.
  ///
  /// Usa documentos individuais na coleção `likes/` com ID composto,
  /// garantindo operações idempotentes e sem duplicação.
  const LikesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'likesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$likesControllerHash();

  @$internal
  @override
  LikesController create() => LikesController();
}

String _$likesControllerHash() => r'51ba5cf036ebc1d0aca3ea6252bf4a34b1182ffa';

/// ============================================================================
/// SISTEMA DE LIKES - ARQUITETURA PROFISSIONAL
/// ============================================================================
///
/// Estrutura no Firestore:
///
/// likes/{likeId}
///   ├── fromUserId: String (quem deu o like)
///   ├── toUserId: String (quem recebeu o like)
///   └── createdAt: Timestamp
///
/// Onde likeId = "${fromUserId}_${toUserId}" (garante unicidade/idempotência)
///
/// users/{userId}
///   └── favoriteCount: int (atualizado atomicamente via transação)
///
/// ============================================================================
/// Controller para gerenciar likes do usuário logado.
///
/// Usa documentos individuais na coleção `likes/` com ID composto,
/// garantindo operações idempotentes e sem duplicação.

abstract class _$LikesController extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Verifica se um item específico está curtido pelo usuário atual.
/// Otimizado para reconstruir apenas quando este ID específico muda.

@ProviderFor(isLiked)
const isLikedProvider = IsLikedFamily._();

/// Verifica se um item específico está curtido pelo usuário atual.
/// Otimizado para reconstruir apenas quando este ID específico muda.

final class IsLikedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Verifica se um item específico está curtido pelo usuário atual.
  /// Otimizado para reconstruir apenas quando este ID específico muda.
  const IsLikedProvider._({
    required IsLikedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isLikedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isLikedHash();

  @override
  String toString() {
    return r'isLikedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isLiked(ref, argument);
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
    return other is IsLikedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isLikedHash() => r'00c720adaa0cbacfe1544e8a653670f222634db4';

/// Verifica se um item específico está curtido pelo usuário atual.
/// Otimizado para reconstruir apenas quando este ID específico muda.

final class IsLikedFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  const IsLikedFamily._()
    : super(
        retry: null,
        name: r'isLikedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Verifica se um item específico está curtido pelo usuário atual.
  /// Otimizado para reconstruir apenas quando este ID específico muda.

  IsLikedProvider call(String targetUserId) =>
      IsLikedProvider._(argument: targetUserId, from: this);

  @override
  String toString() => r'isLikedProvider';
}

/// Retorna a quantidade de likes que o usuário atual deu.

@ProviderFor(userLikesCount)
const userLikesCountProvider = UserLikesCountProvider._();

/// Retorna a quantidade de likes que o usuário atual deu.

final class UserLikesCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Retorna a quantidade de likes que o usuário atual deu.
  const UserLikesCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLikesCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userLikesCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return userLikesCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$userLikesCountHash() => r'e42002ae37c0d30ba70981f357b164982e643aae';
