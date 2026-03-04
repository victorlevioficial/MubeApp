# Plano de Implementacao: Feature "Gigs" — MubeApp

## Objetivo

Implementar a feature "Gigs" no MubeApp como um marketplace de oportunidades musicais onde qualquer usuario autenticado com cadastro concluido pode publicar oportunidades e outros usuarios podem se candidatar. A feature inclui criacao, descoberta, candidatura, acompanhamento, encerramento e avaliacoes pos-gig.

## Decisoes de Produto

- Nome da feature: `gigs`
- Navegacao principal: nova aba `Gigs` na posicao central
- Nova aba final: `Mais`
- `Mais` substitui a aba raiz atual de `Settings`, mas sem quebrar rotas existentes de `Settings`, `Favorites`, `Notifications`, `MatchPoint` e `Profile`
- MatchPoint sai da bottom navigation e passa a ser um item dentro de `Mais`
- O item MatchPoint em `Mais` continua condicionado a `isMatchpointAvailableForType(userType)`
- Quem pode criar: todos os perfis com cadastro concluido
- Midia: apenas texto na V1
- Cachê: opcional, com `fixed`, `negotiable`, `volunteer`, `tbd`
- Vagas: criador define quantidade e pode aceitar multiplos candidatos
- Candidatura: privada; apenas o criador ve a lista de candidatos
- Contador publico: numero total de candidaturas pode ser exibido
- Avaliacao: 1-5 estrelas + comentario, apenas apos gig concluido com participantes aceitos
- Limite: maximo de 5 gigs ativos por usuario
- Cancelamento: permitido; delecao logica nao sera exposta ao app na V1
- Edicao: permitida, mas campos sensiveis exigem restricoes apos surgirem candidaturas
- Comunicacao: nao existe chat dedicado por gig na V1; apos o aceite, o criador pode enviar mensagem ao candidato usando o chat ja existente do app
- Tipos de gig: `show_ao_vivo`, `evento_privado`, `gravacao`, `ensaio_jam`, `outro`
- Status: `open`, `closed`, `expired`, `cancelled`

## Observacoes de Arquitetura do Projeto

- Seguir o padrao atual do app: Flutter + Riverpod 3 + GoRouter + Firebase
- Preferir `@riverpod` e arquivos gerados em vez de concentrar providers manuais em um unico arquivo
- Nao editar arquivos `*.g.dart` e `*.freezed.dart` manualmente
- Reutilizar `AppConfig` para listas de generos, instrumentos, funcoes e services; nao hardcode listas paralelas
- Toda a feature Gigs deve ser implementada dentro do design system existente do app
- Reutilizar tokens, tema, componentes e padroes visuais de `lib/src/design_system/`
- Nao criar paleta, tipografia, espacamento, raios ou estilos paralelos para a feature
- Antes de criar componente novo, verificar se ja existe equivalente compartilhado no design system
- Nao usar `print`; usar `AppLogger`

---

## FASE 1 — Modelo de Dados e Backend

### 1.1 Firestore Constants

Arquivo: `lib/src/constants/firestore_constants.dart`

Adicionar novas collections/subcollections:

- `gigs = 'gigs'`
- `gigApplications = 'gig_applications'`
- `gigReviews = 'gig_reviews'`

Adicionar campos especificos em uma classe dedicada `GigFields` para evitar inflar `FirestoreFields` com chaves muito especificas:

- `title = 'title'`
- `description = 'description'`
- `gigType = 'gig_type'`
- `gigDate = 'gig_date'`
- `dateFlexible = 'date_flexible'`
- `locationType = 'location_type'`
- `location = 'location'`
- `geohash = 'geohash'`
- `genres = 'genres'`
- `requiredSkills = 'required_skills'`
- `requiredRoles = 'required_roles'`
- `slotsTotal = 'slots_total'`
- `slotsFilled = 'slots_filled'`
- `compensationType = 'compensation_type'`
- `compensationValue = 'compensation_value'`
- `status = 'status'`
- `creatorId = 'creator_id'`
- `applicantCount = 'applicant_count'`
- `createdAt = 'created_at'`
- `updatedAt = 'updated_at'`
- `expiresAt = 'expires_at'`

Campos da subcollection `gig_applications`:

- `applicantId = 'applicant_id'`
- `message = 'message'`
- `status = 'status'`
- `appliedAt = 'applied_at'`
- `respondedAt = 'responded_at'`

Campos da collection `gig_reviews`:

- `gigId = 'gig_id'`
- `reviewerId = 'reviewer_id'`
- `reviewedUserId = 'reviewed_user_id'`
- `rating = 'rating'`
- `comment = 'comment'`
- `reviewType = 'review_type'`
- `createdAt = 'created_at'`

Observacao:

- `slots_filled` e `applicant_count` devem ser tratados como campos derivados de ownership do backend; o cliente nao deve manter esses contadores em paralelo.

### 1.2 Domain Models

Diretorio: `lib/src/features/gigs/domain/`

Arquivos sugeridos:

- `gig.dart`
- `gig_application.dart`
- `gig_review.dart`
- `gig_filters.dart`
- `gig_type.dart`
- `gig_status.dart`
- `gig_location_type.dart`
- `compensation_type.dart`
- `application_status.dart`
- `review_type.dart`

Diretrizes:

- Usar `@freezed` seguindo o padrao do projeto
- Persistir IDs de config, nao labels. Ex.: generos e instrumentos devem usar os mesmos IDs de `AppConfig`
- Implementar `fromFirestore` ou `fromJson` + adapter conforme o modelo real escolhido
- Colocar getters computados apenas quando forem deterministas e baratos, por exemplo:
  - `displayCompensation`
  - `isExpired`
  - `spotsRemaining`
  - `canEdit`

### 1.3 Data Layer

Diretorio: `lib/src/features/gigs/data/`

Arquivo principal: `gig_repository.dart`

Responsabilidades:

- Ler/gravar `gigs`
- Ler/gravar subcollection `gig_applications`
- Ler/gravar `gig_reviews`
- Trabalhar com `FirebaseFirestore`
- Obter usuario atual a partir dos providers/autenticacao ja existentes

Metodos base:

- `watchGigs(GigFilters filters) -> Stream<List<Gig>>`
- `watchMyGigs() -> Stream<List<Gig>>`
- `watchGigById(String gigId) -> Stream<Gig?>`
- `createGig(GigDraft draft) -> Future<String>`
- `updateGig(String gigId, GigUpdate update) -> Future<void>`
- `cancelGig(String gigId) -> Future<void>`
- `applyToGig(String gigId, String message) -> Future<void>`
- `withdrawApplication(String gigId) -> Future<void>`
- `watchApplications(String gigId) -> Stream<List<GigApplication>>`
- `updateApplicationStatus(String gigId, String applicationId, ApplicationStatus status) -> Future<void>`
- `watchMyApplications() -> Stream<List<GigApplication>>`
- `hasApplied(String gigId) -> Future<bool>`
- `submitReview(GigReviewDraft review) -> Future<void>`
- `watchReviewsForUser(String userId) -> Stream<List<GigReview>>`
- `getAverageRating(String userId) -> Future<double?>`

Correcoes importantes para a implementacao:

- `watchMyApplications()` deve usar `collectionGroup('gig_applications')`, nao uma collection raiz
- `watchGigs()` nao deve prometer todos os filtros 100% no servidor; alguns filtros terao de ser pos-processados no cliente ou em backend auxiliar
- Filtros viaveis no Firestore para V1:
  - `status`
  - `creator_id`
  - `gig_type`
  - eventualmente um `array-contains-any` simples para generos ou funcoes
- Filtros que provavelmente exigirao pos-filtro:
  - raio de distancia real
  - faixa de cachê combinada com outros filtros
  - combinacoes complexas de arrays

### 1.4 Firestore Security Rules

Arquivo: `firestore.rules`

Regras de V1:

- Leitura publica apenas para gigs visiveis (`open`, opcionalmente `closed` se isso fizer sentido de produto)
- Criacao apenas por usuario autenticado com `creator_id == request.auth.uid`
- Update apenas pelo criador
- Delete negado para o cliente
- Em `gig_applications`:
  - candidato autenticado pode criar apenas a propria candidatura
  - candidato pode ler/remover a propria candidatura
  - criador do gig pai pode ler todas as candidaturas daquele gig
- Em `gig_reviews`:
  - criar apenas autenticado
  - editar/deletar negado
  - leitura publica

Observacao critica:

- Firestore Rules nao conseguem impor de forma confiavel o limite agregado de "5 gigs ativos" por usuario
- Essa regra deve ser garantida em backend transacional, callable function, ou estrategia de contador por usuario
- O mesmo vale para validacoes de "participou do gig" antes de avaliar

### 1.5 Firestore Indexes

Arquivo: `firestore.indexes.json`

Indices previstos:

- `gigs`: `(status ASC, created_at DESC)`
- `gigs`: `(status ASC, gig_type ASC, created_at DESC)`
- `gigs`: `(creator_id ASC, status ASC, created_at DESC)`
- `gig_reviews`: `(reviewed_user_id ASC, created_at DESC)`
- `gig_applications` via `collectionGroup`: `(applicant_id ASC, applied_at DESC)`

Observacao:

- Se houver filtro por geohash, isso provavelmente exigira indice proprio e talvez outra estrategia de consulta
- So adicionar indice depois de confirmar a query exata do repositório

### 1.6 Cloud Functions

Arquivos:

- `functions/src/gigs.ts`
- `functions/src/index.ts`

Funcoes necessarias para V1:

- `onGigCreated`
  - calcular `expires_at`
  - preencher defaults normalizados
- `expireOpenGigs` agendada
  - fechar gigs `open` com `expires_at <= now`
- `onApplicationCreated`
  - enviar notificacao ao criador
  - atualizar contadores derivados no documento pai
- `onApplicationDeleted`
  - decrementar contadores derivados quando necessario
- `onApplicationStatusChanged`
  - enviar notificacao ao candidato
  - atualizar `slots_filled`
  - fechar o gig se preencher todas as vagas
- `onGigCancelled`
  - notificar candidatos
- `closeFinishedGigs` agendada
  - para gigs com data no passado e candidatos aceitos
  - mover para `closed`
  - disparar fluxo de review

Correcao importante:

- Nao duplicar ownership de contadores entre client e backend
- Se `applicant_count` e `slots_filled` forem derivados, o cliente nao deve incrementar/decrementar esses campos

### 1.7 Notificacoes Inteligentes

Implementar em fases.

V1 segura:

- Ao criar um gig, notificar usuarios potencialmente elegiveis com heuristica simples
- Priorizar:
  - `tipo_perfil == profissional`
  - overlap de `generosMusicais`, `instrumentos` ou `funcoes`
  - excluir `creator_id`
  - exigir `fcm_token`

Restricao tecnica importante:

- Nao assumir uma query unica no Firestore combinando geohash por prefixo + arrays + filtros adicionais
- Se localizacao entrar na V1, usar apenas pre-filtro grosseiro e refinamento em memoria no backend
- Se isso aumentar a complexidade, deixar "push inteligente por localizacao" para V1.1 e lancar primeiro sem matching geografico fino

---

## FASE 2 — Providers Riverpod

Diretorio: `lib/src/features/gigs/`

Seguir o padrao local com `@riverpod`, em vez de concentrar tudo em providers manuais.

Arquivos sugeridos:

- `data/gig_repository.dart`
- `data/gig_repository.g.dart`
- `presentation/providers/gig_streams.dart`
- `presentation/providers/gig_filters_controller.dart`
- `presentation/controllers/create_gig_controller.dart`
- `presentation/controllers/gig_actions_controller.dart`
- `presentation/controllers/gig_review_controller.dart`

Providers sugeridos:

- `gigRepositoryProvider`
- `gigFiltersControllerProvider`
- `gigsStreamProvider`
- `myGigsStreamProvider`
- `gigDetailProvider`
- `gigApplicationsProvider`
- `myApplicationsProvider`
- `hasAppliedProvider`
- `userReviewsProvider`
- `userAverageRatingProvider`

Correcao importante:

- Filtro nao precisa ser `AsyncNotifier`
- Preferir um `Notifier<GigFilters>` para estado de filtros
- A lista em si pode ser um `StreamProvider` derivado dos filtros

---

## FASE 3 — Presentation Layer

Diretorio: `lib/src/features/gigs/presentation/`

### 3.1 Controllers

Controladores recomendados:

- `gig_filters_controller.dart`
  - `Notifier<GigFilters>`
  - metodos: `updateFilters`, `clearFilters`, `setLocationFilter`, `setCompensationFilter`
- `create_gig_controller.dart`
  - `AsyncNotifier<void>`
  - responsavel por submit do formulario
- `gig_actions_controller.dart`
  - `AsyncNotifier<void>`
  - `applyToGig`, `withdrawApplication`, `cancelGig`, `updateGig`, `acceptApplication`, `rejectApplication`
- `gig_review_controller.dart`
  - `AsyncNotifier<void>`
  - `submitReview`

Correcao importante:

- Evitar um `gig_detail_controller` que replique estado ja disponivel por streams/providers
- Estados como `isCreator`, `hasApplied` e `canApply` devem ser derivados da combinacao de providers, nao persistidos como fonte primaria separada

### 3.2 Telas

Arquivos sugeridos:

- `gigs_screen.dart`
- `gig_detail_screen.dart`
- `create_gig_screen.dart`
- `gig_applicants_screen.dart`
- `gig_review_screen.dart`
- `my_gigs_screen.dart`
- `my_applications_screen.dart`
- `widgets/gig_card.dart`
- `widgets/gig_filters_sheet.dart`
- `widgets/gig_status_badge.dart`
- `widgets/gig_compensation_chip.dart`
- `widgets/gig_type_chip.dart`
- `widgets/star_rating_widget.dart`
- `widgets/user_rating_display.dart`

Diretrizes de UI:

- Toda a UI da feature deve seguir o design system atual do app
- Reutilizar tokens e componentes do design system
- Reutilizar especificamente cores, tipografia, espacamentos, radius, motion e superficies ja definidas
- Reutilizar `AppConfig` para popular seletores
- Strings em `pt`/`en` via `l10n`
- Lista principal pode usar stream + pull to refresh apenas para invalidacao manual; nao criar refresh falso se a fonte ja e reativa
- Acoes de mensagem devem reutilizar a infraestrutura de chat existente; nao criar conversa/thread especifica por gig na V1

Restricoes visuais:

- Nao hardcode cores, paddings, border radius ou estilos de texto se houver token equivalente
- Nao introduzir widgets visuais "isolados" da feature se o app ja tiver componente compartilhado equivalente
- Se surgir necessidade real de componente novo, ele deve ser desenhado para ser reutilizavel e entrar no design system, nao ficar exclusivo de `gigs`

Estados de comunicacao na feature:

- Antes do aceite: nenhum CTA de mensagem entre criador e candidato dentro da feature Gigs
- Apos `accepted`: exibir botao `Enviar mensagem`
- O botao `Enviar mensagem` deve abrir a conversa usando a navegacao/infra de chat ja existente no app

---

## FASE 4 — Navegacao

### 4.1 Route Paths

Arquivo: `lib/src/routing/route_paths.dart`

Adicionar:

- `gigs = '/gigs'`
- `gigCreate = '/gigs/create'`
- `gigDetail = '/gigs/:gigId'`
- `gigApplicants = '/gigs/:gigId/applicants'`
- `gigReview = '/gigs/:gigId/review/:userId'`
- `myGigs = '/my-gigs'`
- `myApplications = '/my-applications'`
- `more = '/more'`

Helpers:

- `gigDetailById(String gigId)`
- `gigApplicantsById(String gigId)`
- `gigReviewFor(String gigId, String userId)`

### 4.2 App Router

Arquivo: `lib/src/routing/app_router.dart`

Novo shell de 5 tabs:

- Branch 0: `Feed`
- Branch 1: `Search`
- Branch 2: `Gigs`
- Branch 3: `Chat`
- Branch 4: `More`

Correcao importante para reduzir risco:

- `Settings`, `Favorites`, `Notifications`, `MatchPoint` e `ProfileEdit` devem continuar acessiveis nas rotas atuais
- `MoreScreen` deve funcionar como menu/entrypoint para essas rotas, e nao como re-homing obrigatorio de tudo na primeira iteracao
- Isso preserva deep links, referencias existentes a `RoutePaths.settings`, `RoutePaths.favorites`, `RoutePaths.notifications` e `RoutePaths.matchpoint`

Rotas top-level fora do shell para ocultar a bottom bar:

- `gigCreate`
- `gigDetail`
- `gigApplicants`
- `gigReview`
- `myGigs`
- `myApplications`
- manter top-level existentes ja usadas por outras features

### 4.3 Main Scaffold

Arquivo: `lib/src/design_system/components/navigation/main_scaffold.dart`

Ajustes:

- substituir a logica atual de destino central `Match` por `Gigs`
- trocar o ultimo item de `Config` para `Mais`
- simplificar a logica de destinos visiveis; `More` deve estar sempre presente
- a regra de disponibilidade do MatchPoint deixa de controlar o shell e passa a controlar apenas a exibicao do item dentro de `More`

### 4.4 Tela "Mais"

Novo modulo leve:

- `lib/src/features/more/presentation/more_screen.dart`

Itens da tela:

- Meu Perfil
- Meus Gigs
- Minhas Candidaturas
- MatchPoint
- Favoritos
- Notificacoes
- Configuracoes

Observacao:

- O item MatchPoint deve respeitar `isMatchpointAvailableForType`

---

## FASE 5 — Integracoes com Features Existentes

### 5.1 Perfil Publico

Arquivo: `lib/src/features/profile/presentation/public_profile_screen.dart`

Adicionar:

- media de avaliacoes
- numero de reviews
- CTA para ver todas as avaliacoes, se a tela/lista de reviews for incluida na V1

### 5.2 Push Notifications

Arquivos a revisar:

- `lib/src/app.dart`
- `lib/src/core/services/push_notification_service.dart`
- opcionalmente `lib/src/features/notifications/domain/notification_model.dart`

Correcao importante:

- Hoje a navegacao por push ja usa `message.data['route']` em `app.dart`
- Para gigs, preferir payloads com `route` pronto sempre que possivel
- So adicionar novos handlers/client-side se o payload exigir logica adicional
- Se a feature tambem gravar notificacoes em Firestore para a tela de notificacoes, sera necessario expandir `NotificationType` e seu parsing

Payloads esperados:

- `gig_new_applicant`
- `gig_application_accepted`
- `gig_application_rejected`
- `gig_cancelled`
- `gig_matching`
- `gig_expired`

### 5.4 Integracao com Chat Existente

Arquivos a revisar:

- `lib/src/routing/route_paths.dart`
- `lib/src/routing/app_router.dart`
- feature de chat existente

Regras:

- Nao criar chat dedicado por gig na V1
- Apos aceitar uma candidatura, o criador pode iniciar conversa com o candidato usando o chat ja existente do app
- O CTA `Enviar mensagem` deve navegar para a conversa existente, criando-a se a infraestrutura atual de chat suportar esse fluxo
- Se a infraestrutura atual exigir precondicoes para criar/abrir conversa, essa integracao deve ser detalhada antes da implementacao

### 5.3 Localizacao

Arquivos:

- `lib/l10n/app_pt.arb`
- `lib/l10n/app_en.arb`

Adicionar todas as strings da feature.

---

## FASE 6 — Avaliacoes

### 6.1 Fechamento do Gig e Gatilho de Review

Fluxo recomendado:

- Apenas gigs com `gig_date` e ao menos um participante aceito entram no fluxo automatico de review
- Job agendado identifica gigs ja ocorridos e ainda `open`
- Backend altera status para `closed`
- Backend sinaliza usuarios elegiveis para avaliar
- No app, exibir CTA de review somente para participantes elegiveis que ainda nao avaliaram

### 6.2 Protecoes

- Um review por par `reviewer_id + reviewed_user_id + gig_id`
- Review apenas para participantes reais do gig
- Reviews imutaveis apos criacao

---

## Ordem de Execucao Recomendada

1. Constants + enums + domain models
2. Repository + queries basicas
3. Providers Riverpod com `@riverpod`
4. `GigsScreen` + `GigCard` + filtros
5. `CreateGigScreen` + `CreateGigController`
6. Navegacao: nova aba `Gigs` + nova aba `More`
7. `GigDetailScreen` + candidatura + gerenciamento de candidaturas
8. `MyGigsScreen` + `MyApplicationsScreen`
9. Rules + indexes
10. Cloud Functions para expiracao, contadores e notificacoes
11. Reviews
12. Integracoes finais com perfil, notificacoes e l10n

---

## Verificacao

### Testes Unitarios

Diretorios:

- `test/unit/features/gigs/domain/`
- `test/unit/features/gigs/data/`
- `test/unit/features/gigs/presentation/`

Casos minimos:

- parse de `Gig`, `GigApplication`, `GigReview`
- getters computados
- sanitizacao de filtros
- regras de permissao de acao no repositorio/controladores

### Testes de Widget

Diretorio:

- `test/widget/features/gigs/`

Casos minimos:

- render de `GigCard`
- lista vazia em `GigsScreen`
- filtros aplicados
- validacoes do formulario de criacao
- estados de `GigDetailScreen`

### Testes de Rota

Diretorio:

- `test/unit/routing/`

Casos minimos:

- shell com 5 tabs
- rotas novas resolvendo corretamente
- `More` abrindo destinos existentes sem quebrar as rotas legadas

### Verificacao Manual

1. Verificar bottom navigation com `Feed`, `Busca`, `Gigs`, `Chat`, `Mais`
2. Verificar que `MatchPoint` saiu da barra e aparece em `Mais` apenas quando elegivel
3. Criar gig com sucesso e validar limite de 5 ativos
4. Candidatar-se a um gig e validar atualizacao de estado
5. Aceitar/rejeitar candidatura e validar notificacoes
6. Cancelar gig e validar bloqueio de novas acoes
7. Fechar gig concluido e validar fluxo de review

---

## Fora do Escopo da V1

- anexos, fotos e midia no gig
- chat dedicado por gig, conversa exclusiva por anuncio, ou historico de mensagens vinculado ao gig
- busca geografica precisa por raio com indexacao espacial avancada
- analytics de conversao de gigs
- recomendacao altamente personalizada de oportunidades
