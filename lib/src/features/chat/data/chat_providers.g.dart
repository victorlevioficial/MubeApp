// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider simples do ChatRepository (singleton)

@ProviderFor(chatRepository)
const chatRepositoryProvider = ChatRepositoryProvider._();

/// Provider simples do ChatRepository (singleton)

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  /// Provider simples do ChatRepository (singleton)
  const ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'ebcbc91d155adadebcdb2eb3a926a3bc7b76c3e3';

/// Stream de conversas do usuário autenticado
///
/// Ordenado por lastMessageTime (repository já ordena)
/// Limitado a 100 conversas

@ProviderFor(userConversationsStream)
const userConversationsStreamProvider = UserConversationsStreamProvider._();

/// Stream de conversas do usuário autenticado
///
/// Ordenado por lastMessageTime (repository já ordena)
/// Limitado a 100 conversas

final class UserConversationsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConversationPreview>>,
          List<ConversationPreview>,
          Stream<List<ConversationPreview>>
        >
    with
        $FutureModifier<List<ConversationPreview>>,
        $StreamProvider<List<ConversationPreview>> {
  /// Stream de conversas do usuário autenticado
  ///
  /// Ordenado por lastMessageTime (repository já ordena)
  /// Limitado a 100 conversas
  const UserConversationsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userConversationsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userConversationsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<ConversationPreview>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ConversationPreview>> create(Ref ref) {
    return userConversationsStream(ref);
  }
}

String _$userConversationsStreamHash() =>
    r'1e8471a9e588f7e80e8d698b0a4029c9beae3581';

/// Stream de mensagens de uma conversa específica
///
/// Limitado a 50 mensagens (repository já ordena)

@ProviderFor(messagesStream)
const messagesStreamProvider = MessagesStreamFamily._();

/// Stream de mensagens de uma conversa específica
///
/// Limitado a 50 mensagens (repository já ordena)

final class MessagesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Message>>,
          List<Message>,
          Stream<List<Message>>
        >
    with $FutureModifier<List<Message>>, $StreamProvider<List<Message>> {
  /// Stream de mensagens de uma conversa específica
  ///
  /// Limitado a 50 mensagens (repository já ordena)
  const MessagesStreamProvider._({
    required MessagesStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messagesStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messagesStreamHash();

  @override
  String toString() {
    return r'messagesStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Message>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Message>> create(Ref ref) {
    final argument = this.argument as String;
    return messagesStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessagesStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messagesStreamHash() => r'08a190aa807940fd27c40af8c34883e78804059b';

/// Stream de mensagens de uma conversa específica
///
/// Limitado a 50 mensagens (repository já ordena)

final class MessagesStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Message>>, String> {
  const MessagesStreamFamily._()
    : super(
        retry: null,
        name: r'messagesStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream de mensagens de uma conversa específica
  ///
  /// Limitado a 50 mensagens (repository já ordena)

  MessagesStreamProvider call(String conversationId) =>
      MessagesStreamProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'messagesStreamProvider';
}

/// Future provider para readUntil do outro usuário
///
/// Carregado uma única vez ao entrar no chat
/// Usado para calcular status ✓✓ na UI

@ProviderFor(readUntil)
const readUntilProvider = ReadUntilFamily._();

/// Future provider para readUntil do outro usuário
///
/// Carregado uma única vez ao entrar no chat
/// Usado para calcular status ✓✓ na UI

final class ReadUntilProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Future provider para readUntil do outro usuário
  ///
  /// Carregado uma única vez ao entrar no chat
  /// Usado para calcular status ✓✓ na UI
  const ReadUntilProvider._({
    required ReadUntilFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'readUntilProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$readUntilHash();

  @override
  String toString() {
    return r'readUntilProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as (String, String);
    return readUntil(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ReadUntilProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$readUntilHash() => r'e07adf91d7a4ee0521ffec133f5e78dc86e30a51';

/// Future provider para readUntil do outro usuário
///
/// Carregado uma única vez ao entrar no chat
/// Usado para calcular status ✓✓ na UI

final class ReadUntilFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, (String, String)> {
  const ReadUntilFamily._()
    : super(
        retry: null,
        name: r'readUntilProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Future provider para readUntil do outro usuário
  ///
  /// Carregado uma única vez ao entrar no chat
  /// Usado para calcular status ✓✓ na UI

  ReadUntilProvider call(String conversationId, String otherUserId) =>
      ReadUntilProvider._(argument: (conversationId, otherUserId), from: this);

  @override
  String toString() => r'readUntilProvider';
}
