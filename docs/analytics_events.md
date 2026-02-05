# Analytics Events Documentation - AppMube

Documentação completa dos eventos de analytics implementados no aplicativo AppMube.

## Overview

O AppMube utiliza Firebase Analytics para rastrear eventos críticos do funil de conversão e comportamento do usuário. Esta documentação descreve todos os eventos implementados, seus parâmetros e onde são disparados.

## Estrutura do Serviço

O analytics é implementado através de:

- **Interface**: [`AnalyticsService`](lib/src/core/services/analytics/analytics_service.dart:5) - Contrato abstrato para permitir mocking em testes
- **Implementação**: [`FirebaseAnalyticsService`](lib/src/core/services/analytics/analytics_service.dart:31) - Implementação usando Firebase Analytics
- **Provider**: [`analyticsServiceProvider`](lib/src/core/services/analytics/analytics_provider.dart:11) - Provider Riverpod para injeção de dependência

## Eventos Implementados

### 1. Autenticação (Auth)

#### `user_registration`
**Disparado quando**: Um novo usuário completa o cadastro com sucesso.
**Local**: [`AuthRepository.registerWithEmailAndPassword()`](lib/src/features/auth/data/auth_repository.dart:40)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `method` | String | Método de registro (ex: 'email', 'google', 'apple') |
| `user_type` | String | Tipo de usuário (ex: 'pending', 'musician', 'band') |

#### `login`
**Disparado quando**: Usuário faz login com sucesso.
**Local**: [`AuthRepository.signInWithEmailAndPassword()`](lib/src/features/auth/data/auth_repository.dart:25)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `method` | String | Método de login (ex: 'email', 'google', 'apple') |

#### `login_error`
**Disparado quando**: Falha no login.
**Local**: [`AuthRepository.signInWithEmailAndPassword()`](lib/src/features/auth/data/auth_repository.dart:25)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `method` | String | Método de login tentado |
| `error_code` | String | Código do erro Firebase |
| `error_message` | String | Mensagem de erro |

#### `registration_error`
**Disparado quando**: Falha no registro.
**Local**: [`AuthRepository.registerWithEmailAndPassword()`](lib/src/features/auth/data/auth_repository.dart:40)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `method` | String | Método de registro tentado |
| `error_code` | String | Código do erro |
| `error_message` | String | Mensagem de erro |

#### `account_deleted`
**Disparado quando**: Usuário exclui sua conta.
**Local**: [`AuthRepository.deleteAccount()`](lib/src/features/auth/data/auth_repository.dart:86)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `user_id` | String | ID do usuário excluído |

---

### 2. MatchPoint

#### `match_interaction`
**Disparado quando**: Usuário dá like ou dislike em um perfil no MatchPoint.
**Local**: [`MatchpointRepository.saveInteraction()`](lib/src/features/matchpoint/data/matchpoint_repository.dart:46)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `target_user_id` | String | ID do usuário avaliado |
| `action` | String | Tipo de interação ('like' ou 'dislike') |
| `is_match` | Boolean | Se houve match mútuo |

#### `match_created`
**Disparado quando**: Dois usuários dão like mútuo e um match é criado.
**Local**: [`MatchpointRepository.saveInteraction()`](lib/src/features/matchpoint/data/matchpoint_repository.dart:46)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `user_id` | String | ID do usuário atual |
| `matched_user_id` | String | ID do usuário que deu match |
| `source` | String | Origem do match ('matchpoint') |

#### `match_interaction_error`
**Disparado quando**: Erro ao salvar interação no MatchPoint.
**Local**: [`MatchpointRepository.saveInteraction()`](lib/src/features/matchpoint/data/matchpoint_repository.dart:46)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `target_user_id` | String | ID do usuário alvo |
| `action` | String | Ação tentada |
| `error_message` | String | Mensagem de erro |

---

### 3. Chat

#### `chat_initiated`
**Disparado quando**: Uma nova conversa é iniciada entre dois usuários.
**Local**: [`ChatRepository.getOrCreateConversation()`](lib/src/features/chat/data/chat_repository.dart:25)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `conversation_id` | String | ID único da conversa |
| `other_user_id` | String | ID do outro usuário |
| `source` | String | Origem da conversa ('direct', 'matchpoint') |

#### `message_sent`
**Disparado quando**: Uma mensagem é enviada com sucesso.
**Local**: [`ChatRepository.sendMessage()`](lib/src/features/chat/data/chat_repository.dart:104)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `conversation_id` | String | ID da conversa |
| `has_media` | Boolean | Se a mensagem contém mídia |

#### `message_sent_error`
**Disparado quando**: Erro ao enviar mensagem.
**Local**: [`ChatRepository.sendMessage()`](lib/src/features/chat/data/chat_repository.dart:104)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `conversation_id` | String | ID da conversa |
| `error_message` | String | Mensagem de erro |

#### `conversation_deleted`
**Disparado quando**: Uma conversa é excluída.
**Local**: [`ChatRepository.deleteConversation()`](lib/src/features/chat/data/chat_repository.dart:262)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `conversation_id` | String | ID da conversa |
| `other_user_id` | String | ID do outro usuário |

---

### 4. Busca (Search)

#### `search_performed`
**Disparado quando**: Uma busca é realizada com sucesso.
**Local**: [`SearchRepository.searchUsers()`](lib/src/features/search/data/search_repository.dart:32)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `query` | String | Termo de busca |
| `results_count` | Integer | Número de resultados retornados |
| `has_filters` | Boolean | Se filtros foram aplicados |
| `category` | String | Categoria filtrada |

#### `search_error`
**Disparado quando**: Erro ao realizar busca.
**Local**: [`SearchRepository.searchUsers()`](lib/src/features/search/data/search_repository.dart:32)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `query` | String | Termo de busca |
| `error_message` | String | Mensagem de erro |

---

### 5. Perfil (Profile)

#### `profile_edit`
**Disparado quando**: Usuário edita seu perfil.
**Local**: [`ProfileController.updateProfile()`](lib/src/features/profile/presentation/profile_controller.dart:21)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `user_id` | String | ID do usuário |

#### `profile_image_updated`
**Disparado quando**: Usuário atualiza foto de perfil.
**Local**: [`ProfileController.updateProfileImage()`](lib/src/features/profile/presentation/profile_controller.dart:86)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `user_id` | String | ID do usuário |

---

### 6. Feed

#### `feed_post_view`
**Disparado quando**: Usuário visualiza um post no feed.
**Local**: [`VerticalFeedList._onItemTap()`](lib/src/features/feed/presentation/widgets/vertical_feed_list.dart:124)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `post_id` | String | ID do post visualizado |

---

### 7. Registro/Onboarding

#### `auth_signup_complete`
**Disparado quando**: Cadastro é concluído com sucesso.
**Local**: [`RegisterController.register()`](lib/src/features/auth/presentation/register_controller.dart:15)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `method` | String | Método de cadastro ('email', 'google', etc) |

#### `matchpoint_filter`
**Disparado quando**: Usuário configura filtros do MatchPoint.
**Local**: [`MatchpointController.saveMatchpointProfile()`](lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:19)

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `instruments` | String | Lista de instrumentos (separados por vírgula) |
| `genres` | String | Lista de gêneros musicais |
| `distance` | Double | Distância máxima configurada |

---

## Eventos Esperados (A Implementar)

Os seguintes eventos ainda precisam ser implementados:

### `profile_view`
- **Descrição**: Visualização de perfil de outro usuário
- **Parâmetros**: `viewed_user_id`, `source`
- **Onde implementar**: Quando navegar para tela de perfil de outro usuário

### `favorite_added` / `favorite_removed`
- **Descrição**: Adicionar/remover favorito
- **Parâmetros**: `target_user_id`
- **Onde implementar**: Repository de favoritos

### `onboarding_complete`
- **Descrição**: Onboarding finalizado
- **Parâmetros**: `user_type`, `steps_completed`
- **Onde implementar**: Controller do onboarding

### `app_error`
- **Descrição**: Erros críticos do aplicativo
- **Parâmetros**: `error_type`, `error_message`, `screen`
- **Onde implementar**: Global error handler

## Boas Práticas

1. **Sempre use o AnalyticsService injetado**: Nunca chame Firebase Analytics diretamente
2. **Trate erros silenciosamente**: Falhas em analytics não devem quebrar o app
3. **Use parâmetros consistentes**: Mantenha nomes de parâmetros padronizados
4. **Documente novos eventos**: Atualize este documento ao adicionar eventos

## Testes

Para mockar o AnalyticsService em testes:

```dart
class MockAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {}
  
  @override
  Future<void> setUserId(String? id) async {}
  
  // ... outros métodos
}
```

## Métricas Principais

Com base nos eventos acima, as seguintes métricas podem ser acompanhadas:

1. **Taxa de Conversão**: `user_registration` → `onboarding_complete`
2. **Engajamento**: `match_interaction` (likes/dislikes por sessão)
3. **Retenção**: `login` events ao longo do tempo
4. **Ativação**: `chat_initiated` após `match_created`
5. **Adoção de Features**: `search_performed`, `matchpoint_filter`

---

*Última atualização: 2026-02-04*
