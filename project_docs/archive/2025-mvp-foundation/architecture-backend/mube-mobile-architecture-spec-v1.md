# Especificação de Arquitetura Mobile (Flutter) — Mube MVP

Este documento define a estrutura técnica, padrões e decisões de arquitetura para o desenvolvimento do aplicativo Mube em Flutter.

## 1. Princípios Fundamentais

*   **Feature-First:** O código é organizado horizontalmente por funcionalidades (`features/auth`, `features/feed`), não verticalmente por tipo (`screens`, `controllers`).
*   **Clean Architecture (Simplificada):** Separação estrita em camadas (Data, Domain, Presentation) dentro de cada feature.
*   **Reatividade:** Uso intensivo de **Riverpod 2.0 (Generator/Annotation)** para injeção de dependência e gerenciamento de estado reativo.
*   **Imutabilidade:** Uso de classes imutáveis (`Freezed`) para estados e modelos de domínio.
*   **Tratamento de Erros:** Erros não silenciam. São capturados na camada de Data, convertidos em `AppException` e tratados na UI via listeners.

---

## 2. Tech Stack (Core)

*   **SDK:** Flutter 3.x (Latest Stable).
*   **State Management / DI:** `flutter_riverpod`, `riverpod_annotation`.
*   **Imutabilidade:** `freezed`, `freezed_annotation`, `json_serializable`.
*   **Navegação:** `go_router` (Suporte a Deep Links e Nested Navigation).
*   **Backend:** `cloud_firestore`, `firebase_auth`, `cloud_functions`, `firebase_messaging`.
*   **Utilitários:** `bitsdojo_window` (se desktop), `geolocator` (GPS), `intl` (formatação).
*   **UI:** Design System próprio (sem dependência de Libs de componentes pesados).

---

## 3. Estrutura de Pastas

```text
lib/
├── main.dart                     # Entry point (Setup RiverpodScope, Firebase)
├── src/
│   ├── app.dart                  # MaterialApp, Theme Setup, Router Config
│   ├── constants/                # Design Tokens (colors, styles), Keys
│   ├── utils/                    # Helpers genéricos (DateFormatter, Validators)
│   ├── exceptions/               # Definição de AppException
│   ├── routing/                  # Configuração do GoRouter (rotas, redirects)
│   ├── common_widgets/           # Widgets reutilizáveis globais (PrimaryButton, Avatar)
│   └── features/                 # Módulos do app
│       ├── auth/                 # Ex: Autenticação
│       │   ├── data/             # AuthRepository (Impl + Interface)
│       │   ├── domain/           # AppUser (Entity)
│       │   └── presentation/     # LoginScreen, AuthController
│       ├── feed/
│       ├── matchpoint/
│       ├── chat/
│       ├── bands/
│       └── profile/
```

---

## 4. Camadas (Detalhe por Feature)

Dentro de cada pasta em `features/`, seguimos este padrão:

### 4.1. Domain (`/domain`)
O coração da feature. Pura lógica Dart, sem Flutter (idealmente).
*   **Entities:** Classes `Freezed` com regras de negócio.
    *   Ex: `Band`, `UserProfile`, `ChatMessage`.
*   **Interfaces (Opcional):** Contratos de repositórios se necessário para testes (mocking).

### 4.2. Data (`/data`)
Resposável por buscar e persistir dados.
*   **DTOs (Data Transfer Objects):** Extensões `.fromJson()` das Entities para mapping do Firestore.
*   **Repositories:** Classes que acessam o Firestore/Functions.
    *   Ex: `FeedRepository`.
    *   Utilizam `Riverpod` para expor métodos que retornam `Future<T>` ou `Stream<T>`.
    *   **Regra:** Traduzem `FirebaseException` para `AppException` (Domain).

### 4.3. Presentation (`/presentation`)
Widgets e Gerenciamento de Estado da UI.
*   **Controllers:** `AsyncNotifier` ou `StateNotifier` gerados pelo Riverpod.
    *   Gerenciam o estado da tela (Loading, Success, Error).
    *   Recebem inputs do usuário e chamam o Repository.
*   **Widgets:** Telas (`Screen`) e componentes visuais.
    *   Usam `ref.watch(controllerProvider)` para reagir a mudanças.
    *   Usam `ref.listen` para agir em erros/sucessos (Snackbars, Navegação).

---

## 5. Estratégia de Estado (Riverpod)

### Provedores (Providers)
*   **Repository Providers:** `@Riverpod(keepAlive: true)` (mantidos vivos).
    *   `@Riverpod(keepAlive: true) feedRepository(...)`
*   **Controller Providers:** Auto-dispose por padrão (limpa memória ao sair da tela).
    *   Exceção: Estados globais como `authController` ou `unreadMessagesCount`.
*   **Data Providers (Cache):** `FutureProvider` e `StreamProvider` para leitura.
    *   Ex: `bandDetailsProvider(id)` faz cache dos dados da banda.

### Fluxo de Dados (Unidirectional)
1.  **UI** exibe dados via `ref.watch(dataProvider)`.
2.  **Usuário** interage (clique).
3.  **UI** chama método no **Controller** (`controller.submit()`).
4.  **Controller** muda estado para `AsyncLoading`.
5.  **Controller** chama **Repository**.
6.  **Repository** chama **Firestore/Function**.
7.  **Controller** recebe resultado e atualiza estado (`AsyncData` ou `AsyncError`).
8.  **UI** reage e atualiza.

---

## 6. Roteamento (GoRouter)

*   **Configuração Central:** `app_router.dart`.
*   **Redirects (Guardas):** Proteção de rotas com base no estado de autenticação (`Stream<User?>`).
    *   Se não logado -> `/login`.
    *   Se logado mas cadastro incompleto (se aplicável) -> `/onboarding`.
*   **Passagem de Parâmetros:**
    *   Via Path (`/band/:id`).
    *   Via Extra (objeto complexo), com fallback se o objeto não existir (deep link).

---

## 7. Temas e Design System

*   **Arquivo Central:** `src/constants/app_theme.dart`.
*   **Definições:**
    *   `ThemeData` customizado.
    *   Cores: `AppColors.primary`, `AppColors.background`.
    *   Tipografia: `AppTextStyles.h1`, `AppTextStyles.body`.
*   **Uso:** `Theme.of(context).colorScheme...` ou atalhos se preferir.

---

## 8. Tratamento de Erros Global

*   **AppException:** Classe base para erros de domínio.
    *   `NoInternetException`
    *   `PermissionDeniedException` (Firestore permission-denied)
    *   `ValidationException` (Regra de negócio violada)
*   **UI Feedback:** Um widget wrapper ou Listener global que exibe `Toast` ou `Dialog` amigável baseado no tipo da exceção.

---

## 9. Práticas Recomendadas

*   **Imports:** Usar imports relativos dentro da própria feature, imports absolutos (`package:mube/...`) entre features diferentes.
*   **Linting:** `flutter_lints` ou `very_good_analysis` (configuração estrita).
*   **AsyncValue:** Sempre usar `.when(data:..., error:..., loading:...)` na UI para tratar estados de carga corretamente.
