# Instagram-like Stories Implementation Plan

## Goal
Adicionar stories efemeros ao Mube com encaixe natural no feed atual, pipeline propria desde o inicio e escopo de MVP alinhado com o produto ja decidido.

## Product contract locked
Este plano assume as decisoes abaixo como fechadas:

1. Todos os tipos de perfil podem publicar story.
2. A bandeja de stories aparece logo abaixo do header do feed.
3. O primeiro item da bandeja e o story do proprio usuario com CTA de publicacao.
4. Depois do proprio usuario, os favoritos aparecem primeiro e os demais perfis elegiveis aparecem em seguida.
5. O MVP inclui imagem e video.
6. Video e obrigatoriamente vertical, em formato 9:16.
7. Cada video pode ter no maximo 15 segundos.
8. Cada usuario pode publicar no maximo 3 stories por dia.
9. A lista de viewers entra no MVP.
10. Bloqueios e elegibilidade valem na UI e no Firestore, mas o asset de midia nao tera bloqueio forte por URL direta no MVP.
11. A feature tera pipeline propria de stories desde o primeiro dia.
12. A qualidade inicial do video deve ser boa; compressao e reducao de custo entram como etapa posterior, se necessario.
13. Foto e video podem ser publicados tanto por captura no app quanto por importacao da galeria do celular.

Assuncao operacional recomendada:
- "3 stories por dia" significa dia calendario no fuso `America/Sao_Paulo`, nao janela movel de 24h.

## Recommended rollout

### Release 1
MVP com:

- publicacao de imagem e video
- video vertical de ate 15s
- expiracao em 24h
- bandeja de stories abaixo do header do feed
- viewer full-screen com tap para avancar ou voltar e hold para pausar
- estado visto ou nao visto por autor
- lista de viewers para o autor
- exclusao do proprio story
- limite de 3 stories por dia

### Release 2
Adicionar:

- analytics de consumo
- budget alerts e observabilidade de custo
- ajuste fino de bitrate, resolucao e tamanho final
- notificacoes opcionais de novos stories

### Release 3
Somente se a metrica justificar:

- respostas via chat
- highlights
- mencoes, stickers, musica, editor avancado

## Why this staged approach is recommended
O projeto ja tem boa base para feed, Firebase, Storage, Functions e navegacao, mas stories ainda exigem:

- contrato proprio de dados efemeros
- pipeline propria de upload e transcode
- agregados para bandeja e visto ou nao visto
- cleanup de midia e expiracao

O caminho mais seguro e entregar um MVP forte, com video desde o inicio, mas sem tentar resolver agora tudo o que seria necessario para paridade alta com Instagram.

## Current state confirmed in code
Os pontos abaixo ja existem e reduzem risco tecnico:

- `lib/src/features/feed/presentation/feed_screen.dart` e `lib/src/features/feed/presentation/feed_screen_ui.dart` ja concentram a superficie natural para a bandeja
- `lib/src/features/profile/presentation/services/media_picker_service.dart` ja mostra que o app tem base para escolher e preparar midia
- `lib/src/features/storage/data/storage_repository.dart` ja mostra experiencia previa com upload de imagem, video e thumbnail
- `functions/src/video_transcode.ts` ja mostra que o app tem pipeline de transcode funcionando no backend
- `functions/src/scheduled.ts` e `functions/src/index.ts` mostram uso real de Functions e jobs agendados
- `lib/src/core/services/push_notification_service.dart` pode ser aproveitado depois para notificacoes de stories

Conclusao pratica:
- nao existe bloqueio estrutural para um MVP de stories
- mas o app atual nao deve simplesmente reaproveitar a pipeline da galeria como esta

## Architecture recommendation

### 1. Firestore model
Nao recomendo embutir stories dentro do documento `users`. O volume de escrita, leitura, expiracao e views e diferente do perfil.

Recomendacao:

- colecao global `stories/{storyId}`
- subcolecao `stories/{storyId}/views/{viewerUid}`
- resumo server-managed em `users/{uid}.story_state`
- agregado por viewer e autor em `users/{viewerUid}/story_seen_authors/{ownerUid}`

`stories/{storyId}`:

- `id`
- `owner_uid`
- `owner_name`
- `owner_photo`
- `owner_type`
- `media_type` (`image` | `video`)
- `media_url`
- `thumbnail_url`
- `caption` opcional
- `status` (`active` | `expired` | `deleted` | `processing`)
- `created_at`
- `expires_at`
- `published_day_key`
- `duration_seconds`
- `aspect_ratio`
- `viewers_count`

`stories/{storyId}/views/{viewerUid}`:

- `viewer_uid`
- `viewer_name`
- `viewer_photo`
- `viewed_at`

`users/{uid}.story_state`:

- `has_active_story`
- `latest_story_id`
- `latest_story_at`
- `latest_story_thumbnail`
- `active_story_count`

`users/{viewerUid}/story_seen_authors/{ownerUid}`:

- `last_seen_story_id`
- `last_seen_at`

Racional:
- `story_state` evita query global cara so para desenhar a bandeja
- `story_seen_authors` resolve o lookup eficiente de visto ou nao visto por autor
- a subcolecao `views` mantem ownership claro para a lista de viewers

### 2. Storage model
Criar namespaces separados dos assets da galeria. Nao reaproveitar caminhos nem presets de encode da galeria.

Sugestao de estrutura:

- `stories_images/{uid}/{storyId}/full.jpg`
- `stories_images/{uid}/{storyId}/thumb.jpg`
- `stories_videos_source/{uid}/{storyId}/source.mp4`
- `stories_videos_master/{uid}/{storyId}/master.mp4`
- `stories_videos_thumbs/{uid}/{storyId}/thumb.jpg`

Diretrizes:

- pipeline propria desde o primeiro dia
- sem reaproveitar automaticamente a pipeline atual da galeria
- encode inicial priorizando boa qualidade, nao compressao agressiva
- tuning de custo depois, baseado em uso real

### 3. Video contract for MVP
O video nao e fase posterior. Ele faz parte do contrato inicial.

Contrato recomendado:

- duracao maxima: `15s`
- orientacao obrigatoria: vertical
- formato alvo: `9:16`
- transcode dedicado para stories
- thumbnail obrigatoria para todos os videos
- video fora do formato esperado deve ser recusado ou recortado antes da publicacao

Recomendacao tecnica inicial:

- manter qualidade boa no lancamento
- evitar compressao muito forte no MVP
- instrumentar tamanho final e bandwidth desde o inicio para ajustar depois

### 4. Publish and view flow
Para quota de `3 stories por dia` e consistencia dos dados, recomendo fluxo com mais responsabilidade no backend.

Fluxo de publicacao:

1. o cliente seleciona a midia em uma tela propria de compose
2. o cliente valida contrato local basico:
   - video vertical
   - ate 15s
   - usuario autenticado
3. o cliente envia a midia para o namespace de stories
4. uma Cloud Function de publicacao valida:
   - elegibilidade do perfil
   - limite de 3 stories no `published_day_key`
   - campos normalizados do story
5. a Function cria ou finaliza o documento em `stories/{storyId}`
6. triggers atualizam `users.story_state`

Fluxo de visualizacao:

1. o cliente abre o viewer a partir da bandeja
2. ao concluir a visualizacao de um story, o cliente grava `stories/{storyId}/views/{viewerUid}`
3. uma trigger atualiza:
   - `viewers_count`
   - `users/{viewerUid}/story_seen_authors/{ownerUid}`

### 5. Backend / Cloud Functions
Recomendacao minima:

- `publishStory`
  - valida elegibilidade
  - valida limite de 3 por dia
  - cria ou finaliza o documento do story
  - atualiza `users.story_state`
- `deleteStory`
  - marca story como deleted
  - remove midia associada
  - recalcula `users.story_state`
- `onStoryViewed`
  - atualiza `viewers_count`
  - atualiza `story_seen_authors`
- `expireStories`
  - marca stories vencidos
  - remove midia do Storage
  - recalcula `story_state`
- `onStoryVideoUploaded`
  - transcode dedicado para stories
  - gera `master.mp4` e thumbnail em caminhos proprios

Inferencia importante:
- Firestore TTL sozinho nao resolve o cleanup completo, porque apagar o documento nao remove os arquivos do Cloud Storage

### 6. Security rules
Mudancas necessarias:

- `firestore.rules`
  - permitir read de stories ativos para usuarios autenticados e elegiveis
  - permitir write em `stories/{storyId}/views/{viewerUid}` apenas para o viewer autenticado
  - bloquear edicao client-side de `users.story_state`
  - bloquear edicao client-side de `story_seen_authors`
- `storage.rules`
  - criar regras dedicadas para os namespaces de stories
  - permitir upload apenas no namespace do usuario autenticado

Observacao importante sobre privacidade do MVP:
- o bloqueio forte do asset em URL direta nao faz parte do escopo inicial
- a visibilidade sera aplicada na UI e no acesso aos documentos, nao no arquivo em si

### 7. Flutter feature structure
Criar `lib/src/features/stories/` com:

- `domain/story_item.dart`
- `domain/story_view_receipt.dart`
- `data/story_repository.dart`
- `presentation/controllers/story_tray_controller.dart`
- `presentation/controllers/story_viewer_controller.dart`
- `presentation/controllers/story_compose_controller.dart`
- `presentation/screens/story_viewer_screen.dart`
- `presentation/screens/create_story_screen.dart`
- `presentation/screens/story_viewers_screen.dart`
- `presentation/widgets/story_tray.dart`
- `presentation/widgets/story_ring_avatar.dart`
- `presentation/widgets/story_progress_bar.dart`

### 8. Design system guardrails
A feature deve seguir o design system real do app desde a primeira entrega.

Guardrails:

- reutilizar tokens de `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius` e `AppMotion`
- reutilizar componentes existentes sempre que fizer sentido, como `UserAvatar`, `OptimizedImage`, `AppButton`, `AppOverlay`, `AppSnackBar`, `AppLoading` e dialogs de confirmacao
- evitar criar bottom sheet, loading, feedback, botoes ou paddings hardcoded sem antes checar o design system
- manter a bandeja, o compose e o viewer visualmente consistentes com o feed atual

Observacao:
- `story_ring_avatar` e `story_progress_bar` podem ser widgets novos, mas devem nascer em cima dos tokens e componentes do design system atual

### 9. Routing
Adicionar em `lib/src/routing/route_paths.dart`:

- `storyCreate`
- `storyViewer`
- `storyViewers`

Adicionar em `lib/src/routing/app_router.dart`:

- rota full-screen para criacao
- rota full-screen para viewer
- rota para lista de viewers do proprio story

### 10. Feed integration
O encaixe correto e no feed, logo abaixo do header.

Recomendacao:

- inserir a bandeja em `lib/src/features/feed/presentation/feed_screen_ui.dart` logo depois de `FeedHeader`
- nao prender a bandeja ao filtro rapido ou ao bloco de spotlight
- manter o CTA do proprio usuario como primeiro item
- ordenar os demais itens assim:
  - favoritos com story ativo
  - demais perfis elegiveis com story ativo
- deduplicar autores entre favoritos e restante

Observacao:
- "mostrar todos" deve ser interpretado como "todos os elegiveis dentro da surface atual de discovery do app", nao todos os perfis do banco em uma query sem limite

## Implementation phases

### Phase 0. Contract and infra lock
Fechar e documentar no codigo:

- maximo de 15s para video
- vertical only
- maximo de 3 stories por dia
- camera e galeria como fontes de foto e video
- viewers list no MVP
- ordem da bandeja
- bandeja abaixo do header do feed
- politica de privacidade do MVP sem bloqueio forte do asset
- pipeline propria de stories
- guardrails obrigatorios de design system

### Phase 1. Backend and storage foundation
Arquivos principais:

- `firestore.rules`
- `storage.rules`
- `functions/src/index.ts`
- `functions/src/scheduled.ts`
- novo `functions/src/stories.ts`

Entregas:

- colecao `stories`
- subcolecao `views`
- agregado `users.story_state`
- agregado `story_seen_authors`
- publicacao server-managed
- cleanup de expiracao
- regras de acesso
- indices Firestore para:
  - `owner_uid + status + created_at`
  - `status + expires_at`

### Phase 2. Dedicated media pipeline
Arquivos principais:

- novo fluxo de stories em `functions/src/stories.ts`
- extensoes necessarias em `lib/src/features/storage/data/storage_repository.dart` ou repositorio proprio da feature
- possivel utilitario proprio de video para stories

Entregas:

- upload de imagem em namespace proprio
- upload de video em namespace proprio
- transcode dedicado para stories
- thumbnail de video consistente
- camera e galeria como origem suportada para foto e video
- validacao de formato vertical
- validacao de duracao maxima

### Phase 3. Flutter domain, repository and routes
Arquivos principais:

- novo `lib/src/features/stories/`
- `lib/src/routing/route_paths.dart`
- `lib/src/routing/app_router.dart`

Entregas:

- modelos de dominio
- repository com publish, delete, fetch e mark viewed
- controllers Riverpod alinhados ao padrao da feature
- rotas de compose, viewer e viewers list

### Phase 4. Feed tray and viewer
Arquivos principais:

- `lib/src/features/feed/presentation/feed_screen_ui.dart`
- novas telas e widgets de stories

Entregas:

- bandeja de stories logo abaixo do `FeedHeader`
- ring visto ou nao visto
- viewer full-screen
- navegacao entre stories do mesmo autor e autores seguintes
- pause, resume e preload basico

### Phase 5. Author flows and viewers list
Arquivos principais:

- `lib/src/features/stories/presentation/screens/create_story_screen.dart`
- `lib/src/features/stories/presentation/screens/story_viewers_screen.dart`

Entregas:

- CTA de publicacao no primeiro item da bandeja
- selecao de midia
- preview antes de publicar
- exclusao do proprio story
- lista de viewers do proprio story

### Phase 6. Observability and cost tuning
Entregas:

- eventos de analytics
- logging com `AppLogger`
- budget alerts no Firebase e Google Cloud
- metricas de erro, latencia e tamanho medio de arquivo
- rate limiting para publicacao e views
- ajuste posterior de bitrate, resolucao e tamanho final se o custo ficar alto

## Test plan

### Flutter
- unit tests do `story_repository`
- unit tests de ordenacao da bandeja
- unit tests de expiracao e limite diario
- widget tests da bandeja abaixo do header
- widget tests do viewer com avanco automatico e pause
- widget tests do fluxo de criacao
- widget tests da lista de viewers

### Backend
- tests de Functions para publicacao e limite de 3 por dia
- tests de Functions para expiracao e recalculo de `story_state`
- tests de `onStoryViewed` e `story_seen_authors`
- tests de rules para leitura e escrita indevida
- validacao de cleanup de Storage

### Manual QA
- publicar imagem
- publicar video vertical de 15s
- rejeitar video fora do contrato
- expirar story
- abrir viewer a partir da bandeja
- trocar de autor
- validar favoritos primeiro
- apagar story pelo autor
- abrir lista de viewers
- validar reconnect e app cold start

## Engineering effort estimate
Estimativa para 1 dev com contexto no projeto:

- backend + pipeline propria: 5 a 7 dias uteis
- Flutter feature + feed tray + viewer: 6 a 8 dias uteis
- compose flow + viewers list + QA: 4 a 6 dias uteis
- observabilidade e ajustes finais: 2 a 3 dias uteis

Estimativa pratica:
- MVP com imagem + video + viewers list + cleanup robusto: cerca de 15 a 22 dias uteis
- tuning de custo e compressao fina: etapa adicional curta depois de medir uso real

## Infra cost assessment
Custos checados em fontes oficiais em 2026-03-10 e ajustados para a decisao atual de qualidade boa no lancamento.

### 1. Billing plan requirement
Cloud Storage for Firebase exige projeto no plano Blaze para manter acesso ao bucket.

Impacto:
- se o projeto ja estiver em Blaze, nao ha novo bloqueio
- se nao estiver, stories dependem disso

### 2. Firestore cost profile
O custo de metadata continua baixo comparado a midia.

Referencia pratica:
- reads, writes e deletes do Firestore tendem a ser baratos no MVP
- mesmo com viewers list, o centro do custo nao sera o Firestore

### 3. Storage cost profile
Storage parado tende a continuar barato.

Implicacao:
- guardar stories por 24h quase nao pesa
- o problema financeiro principal e servir os arquivos muitas vezes

### 4. Egress / bandwidth
Este continua sendo o principal driver de custo.

Implicacao direta para este plano:
- como a decisao e lancar com qualidade boa e sem compressao agressiva, o risco de custo fica mais concentrado em bandwidth
- se o consumo crescer, o primeiro ajuste deve ser o perfil de encode do video

### 5. Video transcode
Video continua sendo o segundo maior driver de custo, atras apenas de bandwidth.

Implicacao:
- o MVP com video e viavel
- mas a conta cresce bem mais rapido do que um MVP image-only

## Example monthly scenario for 1,000 active users
Cenario de ordem de grandeza, nao orcamento fechado:

- `1,000` usuarios ativos
- `100` usuarios publicando `1` story de video por dia
- `350` usuarios assistindo stories por dia
- `8` stories vistos por viewer por dia
- qualidade inicial boa, sem compressao agressiva

Leitura pratica:
- o custo deixa de ser "quase gratis"
- o projeto pode entrar em algumas centenas de reais por mes so com stories se a feature for usada de verdade
- isso nao inviabiliza o MVP, mas reforca a importancia de medir consumo desde o primeiro dia

## Blockers and risks

### No hard blocker for MVP
Com o codigo atual, nao vejo bloqueio estrutural para um MVP bem recortado.

### Real risks if unresolved
1. Bandeja sem agregado de visto ou nao visto
   - sem `story_seen_authors`, a UI tende a virar join caro no cliente
2. Quota diaria sem enforcement server-side
   - sem backend, o limite de 3 por dia fica fragil
3. Reuso acidental da pipeline da galeria
   - isso contradiz a decisao de produto e tende a gerar custo ou qualidade inadequados
4. Video com qualidade boa sem observabilidade
   - sem medir tamanho final e bandwidth, o custo pode surpreender rapido
5. Privacidade do asset
   - no MVP, URL direta nao tera bloqueio forte; isso foi aceito como trade-off

## Final recommendation
Se a meta for colocar stories no ar com contrato claro e sem retrabalho imediato, o melhor caminho agora e:

1. pipeline propria desde o primeiro dia
2. video no MVP com boa qualidade inicial
3. bandeja abaixo do header do feed
4. favoritos primeiro e restantes depois
5. agregados de `story_state` e `story_seen_authors`
6. enforcement server-side do limite de 3 stories por dia
7. tuning de custo so depois de medir uso real

Esse caminho entrega uma experiencia de stories coerente com o app e evita a armadilha de improvisar a feature em cima da galeria atual.

## Sources checked on 2026-03-10
- Firebase Storage Blaze requirement: https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024
- Firestore pricing and free tier: https://firebase.google.com/docs/firestore/pricing
- Google Cloud Firestore operation pricing: https://cloud.google.com/firestore/pricing
- Google Cloud Storage pricing: https://cloud.google.com/storage/pricing
- Cloud Run functions pricing: https://cloud.google.com/run/pricing
- Cloud Scheduler pricing: https://cloud.google.com/scheduler/pricing
- Transcoder API pricing: https://cloud.google.com/transcoder/pricing
