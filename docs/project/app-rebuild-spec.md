# Documento Completo de Reconstrucao do App Mube

Snapshot tecnico gerado em: 2026-04-01  
Versao atual do app: `1.6.0+134`  
Escopo principal: app mobile Flutter em `lib/` com backend Firebase em `functions/`

## 1. Objetivo deste documento

Este documento existe para permitir a reconstrucao do Mube em outra plataforma sem depender de memoria institucional ou de docs antigas que podem estar defasadas.

Ele foi montado a partir do codigo atual, principalmente destes arquivos:

- `pubspec.yaml`
- `lib/main.dart`
- `lib/src/app.dart`
- `lib/src/routing/app_router.dart`
- `lib/src/routing/route_paths.dart`
- `lib/src/constants/firestore_constants.dart`
- `lib/src/features/**`
- `functions/src/index.ts`

Sempre que este documento divergir de docs antigas do repositório, considere o codigo como fonte de verdade.

## 2. O que e o Mube

O Mube e um app de networking profissional para o mercado musical brasileiro. O objetivo do produto e conectar:

- profissionais da musica
- bandas
- estudios
- contratantes e locais

Principais capacidades do produto:

- cadastro e autenticacao
- onboarding por tipo de perfil
- feed de descoberta
- busca com filtros
- perfil publico compartilhavel
- favoritos
- MatchPoint para matching
- chat em tempo real
- publicacao e candidatura em gigs
- stories
- notificacoes
- suporte interno por tickets
- privacidade, bloqueio e moderacao

## 3. Superficies do repositorio

Para recriar o produto, considere que o repositório nao contem apenas o app mobile:

- `lib/`, `android/`, `ios/`, `web/`, `windows/`: app Flutter
- `functions/`: backend Firebase Cloud Functions
- `admin_panel/`: painel administrativo separado
- `landing_page/`: landing page / site institucional

Se a migracao for apenas do app final para outra stack mobile, o nucleo e:

1. app mobile
2. Firestore/Storage/Auth/Messaging
3. Cloud Functions

## 4. Estado atual do produto

### 4.1 Plataforma e idioma

- plataforma principal: mobile-first
- tema: dark only
- locale ativa: `pt`
- locale secundaria existente: `en`
- brand host usado em links publicos: `mubeapp.com.br`

### 4.2 Stack atual

- Flutter 3.8+
- Dart 3.8+
- Riverpod 3
- GoRouter
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Firebase Analytics
- Firebase Crashlytics
- Firebase Performance
- Firebase App Check
- Cloud Functions

### 4.3 Bibliotecas relevantes

- `google_fonts`
- `image_picker`
- `image_cropper`
- `flutter_image_compress`
- `video_player`
- `flutter_local_notifications`
- `share_plus`
- `printing`
- `pdf`
- `in_app_review`
- `geolocator`

## 5. Arquitetura do app

## 5.1 Bootstrap

Arquivo principal: `lib/main.dart`

O bootstrap atual faz:

- preserva o splash nativo
- inicializa Firebase
- ativa App Check
- configura cache offline do Firestore com 100 MB
- inicializa monitoramento de performance
- instala handlers globais de erro
- inicializa logger / Crashlytics
- sobe `ProviderScope(child: MubeApp())`
- remove splash nativo apenas quando a primeira rota real esta pronta

Isso significa que uma reimplementacao precisa preservar:

- inicializacao resiliente
- tela valida durante bootstrap
- suporte a falhas de inicializacao
- instrumentacao global de erro

## 5.2 Estrutura de codigo

Estrutura real do app:

```text
lib/
  main.dart
  firebase_options.dart
  l10n/
  src/
    app.dart
    constants/
    core/
    design_system/
    features/
    routing/
    shared/
    utils/
```

Organizacao funcional:

- `core/`: infraestrutura global
- `design_system/`: tokens, tema e componentes
- `routing/`: roteamento centralizado
- `features/`: funcionalidades por dominio
- `utils/`: helpers globais

## 5.3 Estado e dependencias

Padrao dominante:

- `Provider` para dependencias e services
- `StreamProvider` para streams de Firestore/Auth
- `NotifierProvider` e `AsyncNotifierProvider` para controllers
- `@riverpod` em boa parte do codigo novo

Padrao operacional:

- tela observa estado
- controller orquestra mutacoes
- repository isola Firebase
- side effects longos usam `ref.listenManual(...)` fora do `build`

## 5.4 Navegacao

Fonte de verdade:

- `lib/src/routing/app_router.dart`
- `lib/src/routing/route_paths.dart`
- `lib/src/routing/auth_guard.dart`

Regras centrais:

- splash e a rota inicial
- redirect de auth/onboarding e centralizado
- shell principal usa `StatefulShellRoute.indexedStack`
- tabs reais atuais do shell: Feed, Busca, Gigs, Chat, Conta
- MatchPoint nao e uma tab principal hoje; ele e acessado por rota dedicada

## 5.5 Design system

Fonte canônica atual:

- `docs/reference/design-system-current.md`
- `lib/src/design_system/**`

Contrato visual atual:

- dark only
- Material 3
- cores por `AppColors`
- tipografia principal com `Inter` e `Poppins`
- componentes compartilhados para app bar, botao, inputs, feedback, loading e navegacao
- layout responsivo com bottom bar em telas estreitas e rail em telas largas

Tokens centrais:

- `AppColors`
- `AppTypography`
- `AppSpacing`
- `AppRadius`
- `AppMotion`
- `AppEffects`

## 6. Tipos de usuario e contratos de exibicao

Enum real: `AppUserType`

Tipos:

- `profissional`
- `banda`
- `estudio`
- `contratante`

Contrato de nome publico:

- profissional: usar `profissional.nomeArtistico`
- banda: usar `banda.nomeBanda` com fallbacks legados
- estudio: usar `estudio.nomeEstudio` com fallbacks legados
- contratante: usar `contratante.nomeExibicao`, com fallback para nome curto pessoal

Regra importante: perfis `profissional`, `banda` e `estudio` nao devem expor nome de registro em superficies publicas se nao houver nome publico configurado. Nesses casos, a UI cai em labels genericas como `Profissional`, `Banda` e `Estudio`.

Status de cadastro:

- `tipo_pendente`
- `perfil_pendente`
- `concluido`

Status de conta / visibilidade:

- `ativo`
- `rascunho`
- outros estados podem existir, como `suspenso`

## 7. Jornada principal do usuario

## 7.1 Autenticacao

Telas:

- `/login`
- `/register`
- `/forgot-password`
- `/verify-email`

Capacidades:

- cadastro por email e senha
- login por email e senha
- reset de senha
- verificacao de email
- exclusao de conta
- sync de perfil Auth + Firestore

Comportamento de redirect:

- usuario anonimo vai para cadastro / rotas publicas
- usuario logado mas sem tipo vai para onboarding de tipo
- usuario logado com tipo mas sem perfil vai para formulario de onboarding
- usuario completo cai no app principal

## 7.2 Onboarding

Rotas:

- `/onboarding`
- `/onboarding/form`
- `/onboarding/notifications`

O onboarding atual e em duas fases:

1. escolha do tipo de perfil
2. preenchimento do perfil minimo

Ao concluir:

- `cadastro_status` vira `concluido`
- enderecos salvos podem ser inicializados com base na localizacao escolhida
- `privacy_settings.chat_open` ganha valor default por tipo
- banda nasce como `rascunho`
- outros perfis completos nascem como `ativo`

## 7.3 Campos por tipo de perfil

### Profissional

Campos e comportamentos observados no codigo:

- nome artistico
- celular
- data de nascimento
- genero
- Instagram
- bio
- categorias profissionais
- instrumentos
- funcoes por categoria
- generos musicais
- suporte a backing vocal
- suporte a gravacao remota para perfis de producao
- galeria de fotos e videos
- links de musica

Categorias profissionais atuais:

- singer
- instrumentalist
- dj
- production
- stage_tech
- audiovisual
- education
- luthier
- performance

### Banda

- nome da banda
- Instagram
- bio
- generos musicais
- galeria
- lista de membros
- convites de banda

Regra de ativacao:

- banda precisa de pelo menos 2 integrantes aceitos para sair do estado de rascunho

### Estudio

- nome do estudio
- celular
- Instagram
- tipo de estudio: `commercial` ou `home_studio`
- servicos oferecidos
- bio
- galeria

### Contratante

- nome de exibicao
- tipo de local
- comodidades do local
- celular
- data de nascimento
- genero
- Instagram
- bio

Tipos de local atuais:

- bar
- pub
- restaurant
- cafe
- concert_hall
- events_space
- nightclub
- cultural_center
- hotel
- other

Comodidades de local atuais:

- stage
- sound_system
- lighting
- dressing_room
- backstage
- parking
- accessibility
- air_conditioning
- security
- open_air

## 7.4 Perfil e perfil publico

Rotas principais:

- `/profile/edit`
- `/profile/invites`
- `/profile/manage-members`
- `/user/:uid`
- `/profile/:uid`
- `/@:username`

Capacidades:

- ver perfil publico
- compartilhar perfil
- copiar link
- bloquear usuario
- denunciar usuario
- abrir chat quando permitido
- favoritar
- ver galeria e videos
- ver reviews de gigs
- ver gigs abertas do criador

## 8. Navegacao completa

## 8.1 Tabs principais do shell

| Tab | Rota raiz | Conteudo |
| --- | --- | --- |
| Feed | `/feed` | home do app, stories, destaques e descoberta |
| Busca | `/search` | busca global com filtros |
| Gigs | `/gigs` | vagas, candidaturas e gigs criadas |
| Chat | `/chat` | lista de conversas |
| Conta | `/settings` | hub de configuracoes e atalhos de conta |

## 8.2 Rotas fora do shell

| Rota | Papel |
| --- | --- |
| `/` | splash |
| `/login` | login |
| `/register` | cadastro |
| `/forgot-password` | reset de senha |
| `/verify-email` | verificacao de email |
| `/onboarding` | escolha de tipo |
| `/onboarding/form` | formulario |
| `/onboarding/notifications` | permissao de notificacao |
| `/gallery` | galeria interna de design system |
| `/favorites` | favoritos do usuario |
| `/notifications` | central de notificacoes |
| `/matchpoint` | entrada principal do MatchPoint |
| `/matchpoint/wizard` | setup wizard do MatchPoint |
| `/matchpoint/history` | historico de swipes |
| `/conversation/:conversationId` | conversa sem bottom bar |
| `/stories/create` | criar story |
| `/stories/viewer/:storyId` | viewer de story |
| `/stories/viewers/:storyId` | lista de viewers |
| `/gigs/create` | criar gig |
| `/gigs/:gigId` | detalhe de gig |
| `/gigs/:gigId/applicants` | candidatos da gig |
| `/gigs/:gigId/review/:userId` | review de participante/criador |
| `/legal/:type` | termos e politica |

## 8.3 Rotas internas do hub Conta

| Rota | Papel |
| --- | --- |
| `/settings/my-gigs` | minhas gigs |
| `/settings/my-applications` | minhas candidaturas |
| `/settings/addresses` | enderecos salvos |
| `/settings/privacy` | privacidade |
| `/settings/blocked-users` | bloqueados |
| `/settings/received-favorites` | favoritos recebidos |
| `/settings/support` | suporte |
| `/settings/support/create-ticket` | abrir ticket |
| `/settings/support/my-tickets` | meus tickets |
| `/settings/support/my-tickets/ticket/:ticketId` | detalhe de ticket |

## 9. Catalogo funcional por modulo

## 9.1 Splash e bootstrap

Feature: `features/splash`

Responsabilidades:

- mostrar estado inicial
- esperar bootstrap
- coordenar entrada segura na primeira rota valida

## 9.2 Feed

Feature: `features/feed`

Papel:

- tela inicial principal
- mistura descoberta de perfis com destaques e preview de gigs
- incorpora stories no topo
- usa filtros rapidos por secao

Elementos do feed:

- header custom
- story tray
- spotlight / featured carousel
- secoes por tipo
- lista vertical
- quick filter bar
- preview de gigs abertas

Tecnica atual:

- discovery pool limitado e deterministico
- busca proxima via geohash quando ha localizacao
- fallback para scan limitado do `users`
- ordenacao por distancia quando possivel
- invalidacao por bloqueio e outros efeitos via providers

## 9.3 Busca

Feature: `features/search`

Papel:

- busca global de perfis
- filtros por categoria, subcategoria e atributos

Categorias de busca:

- all
- professionals
- bands
- studios
- venues

Filtros observados:

- termo
- subcategoria profissional
- generos
- instrumentos
- roles
- servicos
- studioType
- canDoBackingVocal
- offersRemoteRecording

Comportamento:

- consulta em lotes de Firestore
- filtros pesados aplicados em memoria
- paginação estavel por `created_at`
- ignora perfis incompletos, inativos e ocultos
- venues/contractors so aparecem se `contratante.isPublic == true`

## 9.4 Favoritos

Feature: `features/favorites`

Capacidades:

- adicionar e remover favorito
- listar favoritos do usuario
- listar favoritos recebidos
- contador agregado de favoritos no perfil alvo

Persistencia:

- cliente escreve em `users/{uid}/favorites/{targetId}`
- backend reage via trigger para atualizar contadores

## 9.5 MatchPoint

Feature: `features/matchpoint`

Papel:

- sistema de matching com swipe
- encontra perfis compatíveis por localizacao aproximada, hashtags e generos

Fluxo atual:

1. wrapper decide entre tela indisponivel, intro ou tabs
2. wizard de configuracao
3. exploracao com deck de swipe
4. tela de matches
5. historico de swipes

Wizard atual:

- passo 1: intencao (`join_band`, `form_band`, `both`)
- passo 2: hashtags
- passo 3: privacidade / visibilidade no app

Disponibilidade:

- disponivel para bandas
- disponivel para profissionais com sinal artistico
- indisponivel para perfis de suporte puro, contratantes e estudios

Quota:

- limite diario de likes
- payload de quota retorna `remaining`, `limit`, `resetTime`

Algoritmo:

- candidatos ativos saem de `users.matchpoint_profile.is_active == true`
- query preferencial por geohash vizinho
- fallback para pool global
- ranking cruza distancia, generos e hashtags
- interacoes ja feitas entram em exclusao

Complementos:

- ranking de hashtags
- busca de hashtags
- auditoria de ranking no backend

## 9.6 Chat

Feature: `features/chat`

Papel:

- conversas 1:1 entre usuarios
- leitura em tempo real
- previews por usuario
- unread count
- fluxo de request/pending em alguns cenarios

Estrutura:

- documento principal em `conversations/{conversationId}`
- mensagens em `conversations/{conversationId}/messages/{messageId}`
- preview por usuario em `users/{uid}/conversationPreviews/{conversationId}`

Tipos de conversa observados:

- `direct`
- `matchpoint`

Capacidades:

- criar ou recuperar conversa deterministica
- mandar mensagem
- responder mensagem
- marcar como lida
- apagar preview
- reavaliar acesso
- unread badge na tab de chat

Regras importantes:

- `conversationId` e deterministico entre dois UIDs
- Cloud Function `initiateContact` exige email verificado
- notificacoes push da conversa aberta sao suprimidas localmente
- ha camada de chat safety para detectar tentativa de tirar conversa da plataforma

## 9.7 Gigs

Feature: `features/gigs`

Papel:

- marketplace de oportunidades / vagas musicais

Hub atual:

- abertas
- minhas candidaturas
- minhas gigs

Capacidades:

- listar gigs
- filtrar gigs
- criar gig
- editar gig
- ver detalhe
- candidatar-se
- revisar candidato ou criador depois da execucao
- acompanhar candidatos
- cancelar / fechar / expirar

Modelo de gig:

- titulo
- descricao
- tipo da gig
- status
- modo de data
- data opcional
- tipo de localizacao
- localizacao / geohash
- generos
- instrumentos exigidos
- funcoes tecnicas exigidas
- servicos de estudio exigidos
- numero total de vagas
- vagas preenchidas
- forma de compensacao
- valor opcional
- criador
- contador de candidatos
- expiracao

Filtros atuais:

- termo
- status
- tipo de gig
- tipo de localizacao
- tipo de compensacao
- generos
- requiredInstruments
- requiredCrewRoles
- requiredStudioServices
- onlyOpenSlots
- onlyMine

Reviews:

- ha review do criador para participante
- ha review do participante para criador
- prompts globais podem lembrar de avaliar depois

## 9.8 Stories

Feature: `features/stories`

Papel:

- stories efemeros de 24 horas
- exibidos no topo do feed

Regras atuais:

- maximo de 3 stories por dia
- video de ate 15 segundos
- vida util de 24 horas

Capacidades:

- publicar story de imagem
- publicar story de video
- listar tray
- abrir viewer
- registrar visualizacao
- listar viewers do story proprio
- excluir story

Ordenacao de tray:

- story do usuario atual no topo
- favoritos recebem destaque
- unseen tem prioridade sobre seen

## 9.9 Notificacoes

Feature: `features/notifications`

Capacidades:

- stream da caixa de notificacoes do usuario
- contador unread
- marcar uma como lida
- marcar todas como lidas
- excluir uma
- excluir todas

Tipos de notificacao observados:

- `chat_message`
- `band_invite`
- `band_invite_accepted`
- `gig_application`
- `gig_application_accepted`
- `gig_application_rejected`
- `gig_cancelled`
- `gig_review_reminder`
- `gig_opportunity`
- `like`
- `system`

Resolucao de rota:

- payload pode trazer `route` pronto
- fallback usa `type`, `gig_id` e `reviewed_user_id`

## 9.10 Bandas e convites

Feature: `features/bands`

Capacidades:

- convidar usuario para banda
- aceitar convite
- recusar convite
- cancelar convite
- sair da banda
- listar bandas em que o usuario esta
- listar convites recebidos e enviados

Backend:

- funcao `manageBandInvite`
- funcao `leaveBand`

Prompt global:

- bandas em rascunho com menos de 2 membros recebem lembrete de formacao

## 9.11 Perfil e edicao de perfil

Feature: `features/profile`

Capacidades:

- editar campos por tipo
- trocar foto de perfil
- subir e ordenar galeria
- galeria com fotos e videos
- trim de video
- links de musica
- avatar thumb + full
- avaliacao media e reviews visiveis em perfil publico

Galeria:

- fotos e videos convivem
- item carrega URLs em varios tamanhos
- video pode passar por transcodificacao

Estado relevante:

- `selectedCategories`
- `selectedGenres`
- `selectedInstruments`
- `selectedRoles`
- `backingVocalMode`
- `instrumentalistBackingVocal`
- `offersRemoteRecording`
- `studioType`
- `selectedServices`
- `bandGenres`
- `contractorVenueType`
- `contractorAmenities`

## 9.12 Settings, privacidade e enderecos

Feature: `features/settings`

Tela de conta atual inclui atalhos para:

- editar perfil
- minhas gigs
- minhas candidaturas
- favoritos
- notificacoes
- enderecos
- minhas bandas / gestao da banda
- trocar senha
- privacidade
- idioma
- suporte
- avaliar app
- termos de uso
- politica de privacidade
- logout
- exclusao de conta

Privacidade:

- `visible_in_home`
- `chat_open`
- outros flags podem existir em `privacy_settings`

Endereco:

- usuario pode salvar ate 5 enderecos
- um endereco pode ser primario
- localizacao e usada para distancia aproximada e ordenacao

## 9.13 Moderacao

Feature: `features/moderation`

Capacidades:

- denunciar usuario
- bloquear usuario
- desbloquear usuario

Impacto do bloqueio:

- feed
- busca
- MatchPoint
- stories
- chat
- perfil publico

Persistencia de bloqueio:

- subcolecao `users/{uid}/blocked/{blockedUserId}`
- espelho legado em `users.blocked_users`

## 9.14 Suporte

Feature: `features/support`

Capacidades:

- FAQ
- abrir ticket
- listar tickets
- ver detalhe do ticket

Status de ticket:

- `open`
- `in_progress`
- `resolved`
- `closed`

Estrutura do ticket:

- id
- userId
- title
- description
- category
- status
- imageUrls
- hasUnreadMessages
- createdAt
- updatedAt

## 9.15 Legal

Feature: `features/legal`

Capacidades:

- exibir Termos de Uso
- exibir Politica de Privacidade
- gerar PDF

Rotas dinamicas:

- `/legal/termsOfUse`
- `/legal/privacyPolicy`

## 9.16 Feature de galeria interna

Feature: `features/gallery`

Papel:

- showcase interno de design system
- nao e funcionalidade de usuario final

## 10. Modelo de dados atual

## 10.1 Documento principal de usuario

Colecao: `users/{uid}`

Campos relevantes observados:

- `uid`
- `email`
- `cadastro_status`
- `tipo_perfil`
- `status`
- `nome`
- `foto`
- `foto_thumb`
- `bio`
- `username`
- `location`
- `geohash`
- `addresses`
- `favorites_count`
- `members`
- `blocked_users`
- `privacy_settings`
- `music_links`
- `matchpoint_profile`
- `fcm_token`
- `fcm_updated_at`
- `created_at`

Objetos aninhados por tipo:

- `profissional`
- `banda`
- `estudio`
- `contratante`

## 10.2 Subcolecoes por usuario

| Path | Finalidade |
| --- | --- |
| `users/{uid}/blocked` | bloqueios |
| `users/{uid}/favorites` | favoritos feitos |
| `users/{uid}/notifications` | notificacoes do usuario |
| `users/{uid}/conversationPreviews` | previews de chat |
| `users/{uid}/story_seen_authors` | ultimo seen por autor de stories |

## 10.3 Chat

| Path | Finalidade |
| --- | --- |
| `conversations/{conversationId}` | metadados da conversa |
| `conversations/{conversationId}/messages/{messageId}` | mensagens |

Campos relevantes de conversa:

- `participants`
- `participantsMap`
- `createdAt`
- `updatedAt`
- `lastMessageText`
- `lastMessageAt`
- `lastSenderId`
- `readUntil`
- `type`

Campos relevantes de preview:

- `otherUserId`
- `otherUserName`
- `otherUserPhoto`
- `lastMessageText`
- `lastMessageAt`
- `lastSenderId`
- `unreadCount`
- `updatedAt`
- `type`
- `isPending`
- `requestCycle`

## 10.4 MatchPoint

| Path | Finalidade |
| --- | --- |
| `interactions` | likes/dislikes |
| `matches` | matches gerados |
| `hashtagRanking` | ranking de hashtags |
| `hashtagRanking/{tag}/dailyUses` | historico diario de uso |

Campos tipicos de `matchpoint_profile`:

- `is_active`
- `intent`
- `generosMusicais`
- `hashtags`
- `target_roles`
- `search_radius`
- `is_public`
- `updated_at`

## 10.5 Gigs

| Path | Finalidade |
| --- | --- |
| `gigs/{gigId}` | gig |
| `gigs/{gigId}/gig_applications/{applicationId}` | candidaturas |
| `gig_reviews/{reviewId}` | reviews entre criador e participante |

## 10.6 Bandas

| Path | Finalidade |
| --- | --- |
| `invites/{inviteId}` | convites de banda |

## 10.7 Stories

| Path | Finalidade |
| --- | --- |
| `stories/{storyId}` | story ativo/processando/expirado |
| `stories/{storyId}/views/{viewerUid}` | visualizacoes do story |

Campos relevantes:

- `owner_uid`
- `owner_name`
- `owner_photo`
- `owner_photo_preview`
- `owner_type`
- `media_type`
- `media_url`
- `thumbnail_url`
- `caption`
- `created_at`
- `expires_at`
- `published_day_key`
- `duration_seconds`
- `aspect_ratio`
- `viewers_count`
- `status`

## 10.8 Outros caminhos

| Path | Finalidade |
| --- | --- |
| `tickets/{ticketId}` | suporte |
| `reports/{reportId}` | denuncias |
| `config/app_data` | taxonomias, flags e builds minimos |
| `deletedUsers/{uid}` | usuarios deletados |

## 11. Storage e midia

## 11.1 Paths observados

| Path | Conteudo |
| --- | --- |
| `profile_photos/{uid}/thumbnail.webp` | avatar pequeno |
| `profile_photos/{uid}/large.webp` | avatar grande |
| `gallery_photos/{uid}/{mediaId}/thumbnail.webp` | galeria foto thumb |
| `gallery_photos/{uid}/{mediaId}/medium.webp` | galeria foto medium |
| `gallery_photos/{uid}/{mediaId}/large.webp` | galeria foto large |
| `gallery_photos/{uid}/{mediaId}/full.webp` | galeria foto full |
| `gallery_videos/{uid}/{mediaId}.mp4` | video de galeria original |
| `gallery_videos_transcoded/...` | videos transcodificados |
| `stories_images/{uid}/{storyId}/full.webp` | story imagem full |
| `stories_images/{uid}/{storyId}/thumb.webp` | story imagem thumb |
| `stories_videos_source/{uid}/{storyId}/source.mp4` | story video original |
| `stories_videos_thumbs/{uid}/{storyId}/thumb.webp` | thumb de story video |

## 11.2 Regras de upload

Validacoes atuais:

- foto: ate 10 MB
- video: ate 100 MB
- imagens permitidas: jpg, jpeg, png, webp, gif
- videos permitidos: mp4, mov, webm

Limites funcionais do perfil:

- fotos: maximo 6
- videos: maximo 3
- total de midias: ate 9 itens como regra funcional do produto

## 12. Backend Firebase Cloud Functions

Arquivo agregador: `functions/src/index.ts`

Modulos exportados:

- `matchpoint.ts`
- `bands.ts`
- `chat.ts`
- `chat_safety.ts`
- `moderation.ts`
- `scheduled.ts`
- `hashtags.ts`
- `support.ts`
- `admin.ts`
- `favorites.ts`
- `users.ts`
- `gigs.ts`
- `video_transcode.ts`
- `stories.ts`
- migracoes de geohash e interactions

Funcoes relevantes por dominio:

### MatchPoint

- `submitMatchpointAction`
- `recordMatchpointRankingAudit`
- `getRemainingLikes`
- `onMatchCreated`
- `onInteractionCreated`

### Bandas

- `manageBandInvite`
- `getPendingInvites`
- `leaveBand`

### Chat

- `initiateContact`
- `logChatPreSendWarning`
- trigger server-side de mensagem em `onMessageCreated`

### Moderacao

- `onReportCreated`
- `liftSuspensions`

### Agendadas

- `pruneOldInteractions`
- `cleanupOrphanedData`
- `updateMatchpointStats`
- `expireFixedDateGigs`
- `expireStories`

### Hashtags

- `onHashtagUsed`
- `recalculateHashtagRanking`
- `getTrendingHashtags`
- `searchHashtags`

### Suporte

- `submitSupportTicket`
- `onTicketCreated`

### Favoritos

- `onFavoriteCreated`
- `onFavoriteDeleted`

### Usuarios

- `deleteAccount`
- `setPublicUsername`
- `syncContractorDisplayName`
- `backfillContractorDisplayNames`

### Gigs

- `onGigCreated`
- `onGigUpdated`
- `onGigDeleted`
- `onGigApplicationCreated`
- `onGigApplicationUpdated`
- `onGigApplicationDeleted`

### Stories e video

- `publishStory`
- `deleteStory`
- `onStoryViewed`
- `onStoryVideoUploaded`
- `onGalleryVideoUploaded`
- `backfillGalleryVideoTranscodes`

## 13. Notificacoes, side effects e prompts globais

## 13.1 Push notifications

Servico principal: `PushNotificationService`

Fluxo:

- pede permissao ou faz bootstrap silencioso
- salva `fcm_token` no documento do usuario
- cria canal local de alta prioridade
- mostra notificacao local em foreground
- abre rota apropriada ao tocar na notificacao

Regras importantes:

- se o usuario estiver dentro da conversa ativa, o banner push daquela conversa e suprimido
- payload tenta resolver rota por `route`, depois por `type` + ids auxiliares

## 13.2 Prompts globais do app

Disparados a partir de `lib/src/app.dart`:

- aviso de atualizacao do app
- lembrete de formacao de banda
- lembrete de review de gig pendente
- prompt de avaliar app na loja

## 13.3 Estado offline e resiliencia

Ha infraestrutura para:

- detectar conectividade
- usar cache do Firestore
- retries pontuais em operacoes de Firestore
- refresh de App Check/Auth em operacoes sensiveis

## 14. Analytics, logs e observabilidade

## 14.1 Analytics

Implementado com `AnalyticsService` e `FirebaseAnalyticsService`.

Eventos relevantes documentados / observados:

- `user_registration`
- `login`
- `login_error`
- `registration_error`
- `account_deleted`
- `match_interaction`
- `match_created`
- `match_interaction_error`
- `chat_initiated`
- `message_sent`
- `message_sent_error`
- `search_performed`
- `search_error`
- `profile_edit`
- `feed_post_view`
- `auth_signup_complete`
- `matchpoint_filter`

## 14.2 Logging

Logger central:

- `AppLogger.info`
- `AppLogger.debug`
- `AppLogger.warning`
- `AppLogger.error`
- `AppLogger.fatal`

Nao usar `print`.

## 14.3 Crash, performance e seguranca

- Crashlytics
- Firebase Performance
- App Check

## 15. Divergencias importantes encontradas

Ao migrar, nao confie cegamente nas docs antigas. Divergencias reais identificadas:

1. `README.md` ainda mostra versao `1.1.3+12`, mas `pubspec.yaml` atual esta em `1.6.0+134`.
2. `ARCHITECTURE.md` diz que o shell principal cobre Feed, Search, MatchPoint, Chat e Settings, mas o router atual usa Feed, Search, Gigs, Chat e Settings.
3. `docs/FIRESTORE_SCHEMA.md` fala em colecoes `support_tickets` e `notifications` top-level; o codigo atual usa `tickets` top-level e `users/{uid}/notifications`.
4. `docs/FIRESTORE_SCHEMA.md` documenta favoritos como colecao top-level `favorites`; o fluxo atual de cliente usa `users/{uid}/favorites`.
5. Chat nao esta modelado apenas como `conversations` + `messages`; o app depende tambem de `users/{uid}/conversationPreviews`.

## 16. Ordem recomendada para reconstruir em outra plataforma

### Fase 1: Fundacao

1. autenticar usuario
2. espelhar documento `users/{uid}`
3. reproduzir guardas de onboarding
4. montar tabs principais e rotas
5. integrar Firestore offline e push

### Fase 2: Produto core

1. feed
2. busca
3. perfil publico
4. favoritos
5. MatchPoint
6. chat

### Fase 3: Monetizacao / profundidade de uso

1. gigs
2. stories
3. notificacoes
4. suporte
5. reviews
6. gestao de bandas

### Fase 4: Polimento operacional

1. prompts globais
2. analytics
3. crash/performance
4. legal
5. admin hooks

## 17. Checklist de paridade para a migracao

- replicar os 4 tipos de perfil
- manter `cadastro_status`
- manter contrato de nome publico por tipo
- preservar shell com 5 tabs
- preservar perfis publicos por `@username` e por UID
- manter subcolecoes por usuario para favoritos, notifications, blocked e conversationPreviews
- manter regras de banda em `rascunho` ate ativacao
- manter MatchPoint fora da tab principal
- manter Gigs como tab principal
- manter stories com 24h e 3 por dia
- manter push com supressao quando conversa estiver aberta
- manter bloqueio afetando feed, busca, stories, MatchPoint e chat

## 18. Resumo executivo para quem vai portar

Se eu tivesse que resumir o produto em poucas frases para um time reimplementar:

- o Mube e um app dark-only de networking musical para o mercado brasileiro
- o coracao do produto e `users`, descoberta, MatchPoint, chat e gigs
- a navegacao principal e Feed, Busca, Gigs, Chat e Conta
- o modelo de dados gira em torno de um documento de usuario com blocos aninhados por tipo de perfil
- o backend depende fortemente de Firestore + Cloud Functions para fan-out, contadores, automacoes, notificacoes e moderacao
- para acertar a migracao, e fundamental reproduzir os contratos de visibilidade, onboarding, naming publico, bloqueio e side effects de notificacao

