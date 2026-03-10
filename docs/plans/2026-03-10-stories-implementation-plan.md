# Instagram-like Stories Implementation Plan

## Goal
Adicionar uma feature de stories efêmeros ao Mube com encaixe natural no feed atual, reaproveitando a stack Flutter + Firebase já existente e evitando reescrever discovery, navegação ou upload de mídia.

## Recommended rollout

### Release 1
Stories de imagem com:

- publicação a partir da galeria/câmera
- expiração em 24h
- bandeja de stories no topo do feed
- viewer full-screen com tap para avançar/voltar e hold para pausar
- estado visto/não visto por autor
- criação do próprio story

### Release 2
Adicionar:

- vídeo curto
- lista de viewers para o autor
- analytics de consumo
- notificações opcionais

### Release 3
Somente se a métrica justificar:

- respostas via chat
- destaques (highlights)
- menções, stickers, música, editor avançado

## Why this staged approach is recommended
O projeto já tem boa base para mídia, Storage, Firebase Functions e navegação, mas ainda não tem:

- grafo de seguidores
- infraestrutura específica para conteúdo efêmero
- moderação forte para vídeo
- editor visual avançado estilo Instagram

Por isso, o caminho mais seguro é entregar um MVP forte primeiro, validando uso e custo antes de buscar paridade alta com Instagram.

## Current state confirmed in code
Os pontos abaixo já existem e reduzem bastante o risco técnico:

- `lib/src/features/feed/presentation/feed_screen.dart` já concentra a superfície natural para a bandeja de stories
- `lib/src/features/profile/presentation/services/media_picker_service.dart` já trata foto, trim e compressão de vídeo
- `lib/src/features/storage/data/storage_repository.dart` já faz upload de imagem, vídeo e thumbnail no Firebase Storage
- `functions/src/video_transcode.ts` já implementa transcode de vídeos no backend
- `lib/src/core/services/push_notification_service.dart` já suporta push e navegação por notificação
- `functions/src/scheduled.ts` e `functions/src/index.ts` mostram que o projeto já usa Cloud Functions e jobs agendados
- `firestore.rules` e `storage.rules` já estão organizados por recursos e ownership

Conclusão prática:
- não existe bloqueio estrutural para um MVP de stories
- o maior risco está em escopo de produto, custo de mídia e regras de visibilidade

## Product decisions assumed in this plan
Para este plano ficar implementável sem abrir uma feature paralela de social graph, assumo:

1. A bandeja de stories do feed mostrará:
   - o story do próprio usuário
   - stories de perfis já carregados pelo feed atual
2. O story expira em 24 horas
3. Apenas perfis concluídos e ativos podem publicar stories
4. Respostas via chat ficam fora do MVP inicial
5. Stories respeitam bloqueios entre usuários
6. Editor avançado com stickers, música e desenho fica fora do MVP

Se a decisão de produto for "stories de pessoas seguidas", então há dependência prévia de um modelo de relacionamento que hoje o app não tem.

## Architecture recommendation

### 1. Firestore model
Não recomendo embutir stories dentro do documento `users`. O volume de escrita, leitura e expiração é diferente do perfil.

Recomendação:

- coleção global `stories/{storyId}`
- subcoleção `stories/{storyId}/views/{viewerUid}`
- resumo server-managed em `users/{uid}.story_state`

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
- `status` (`active` | `expired` | `deleted`)
- `created_at`
- `expires_at`
- `viewers_count`
- `allow_replies`

`stories/{storyId}/views/{viewerUid}`:

- `viewer_uid`
- `viewer_name`
- `viewer_photo`
- `viewed_at`

`users/{uid}.story_state`:

- `has_active_story`
- `latest_story_at`
- `latest_story_thumbnail`
- `active_story_count`

Racional:
- o feed já lê `users`, então `story_state` evita query global extra para desenhar a bandeja
- a coleção `stories` concentra o conteúdo efêmero e facilita cleanup
- a subcoleção `views` mantém ownership claro para a lista de viewers

### 2. Storage model
Criar namespaces separados dos assets de galeria:

- `stories_images/{uid}/{storyId}/thumb.webp`
- `stories_images/{uid}/{storyId}/full.webp`
- `stories_videos/{uid}/{storyId}/source.mp4`
- `stories_videos_transcoded/{uid}/{storyId}/master.mp4`
- `stories_thumbnails/{uid}/{storyId}/thumb.jpg`

Isso evita misturar stories efêmeros com a galeria persistente do perfil.

### 3. Backend / Cloud Functions
Recomendação mínima:

- `onStoryCreatedOrUpdated`
  - recalcula `users/{uid}.story_state`
- `expireStories`
  - marca stories vencidos
  - remove mídia do Storage
  - recalcula `story_state`
- `onStoryVideoUploaded`
  - fase 2
  - reaproveita a lógica existente de transcode com path dedicado

Inferência importante:
- Firestore TTL sozinho não resolve o problema, porque apagar o documento não remove os arquivos do Cloud Storage

### 4. Security rules
Mudanças necessárias:

- `firestore.rules`
  - permitir create/update/delete em `stories/{storyId}` só para o autor
  - permitir read de stories ativos para usuários autenticados elegíveis
  - permitir create em `views/{viewerUid}` apenas para o viewer autenticado
  - bloquear edição client-side de `users.story_state`
- `storage.rules`
  - criar regras para `stories_images`, `stories_videos`, `stories_videos_transcoded` e `stories_thumbnails`

### 5. Flutter feature structure
Criar `lib/src/features/stories/` com:

- `domain/story_item.dart`
- `domain/story_view_receipt.dart`
- `data/story_repository.dart`
- `presentation/controllers/story_tray_controller.dart`
- `presentation/controllers/story_viewer_controller.dart`
- `presentation/controllers/story_compose_controller.dart`
- `presentation/screens/story_viewer_screen.dart`
- `presentation/screens/create_story_screen.dart`
- `presentation/widgets/story_tray.dart`
- `presentation/widgets/story_ring_avatar.dart`
- `presentation/widgets/story_progress_bar.dart`

### 6. Routing
Adicionar em `lib/src/routing/route_paths.dart`:

- `storyCreate`
- `storyViewer`

Adicionar em `lib/src/routing/app_router.dart`:

- rota full-screen para criação
- rota full-screen para viewer

### 7. Feed integration
O encaixe mais natural é no topo do feed.

Recomendação:
- inserir a bandeja de stories acima do conteúdo principal do `FeedScreen`
- usar o próprio resultado do feed para montar a ordem dos autores elegíveis
- incluir o avatar do usuário atual como primeiro item com CTA de publicação

Isso evita criar uma surface paralela de discovery só para stories.

## Implementation phases

### Phase 0. Product lock
Antes de codar, fechar:

- quem aparece na bandeja
- se contratantes podem publicar
- se vídeo entra no MVP ou fica para fase 2
- se replies entram agora ou depois
- se viewers list é obrigatória no MVP

Sem essas decisões, a implementação começa mas o contrato de dados fica instável.

### Phase 1. Backend foundation
Arquivos principais:

- `firestore.rules`
- `storage.rules`
- `functions/src/index.ts`
- `functions/src/scheduled.ts`
- novo `functions/src/stories.ts`

Entregas:

- coleção `stories`
- cleanup de expiração
- recálculo de `users.story_state`
- regras de acesso
- índices Firestore para:
  - `owner_uid + expires_at + created_at`
  - `status + expires_at`

### Phase 2. Flutter domain + repository
Arquivos principais:

- novo `lib/src/features/stories/`
- possível extensão em `lib/src/features/storage/data/storage_repository.dart`

Entregas:

- modelos de domínio
- repository com CRUD
- upload de imagem
- marcador de visualização
- leitura paginada por autor

### Phase 3. Feed tray + viewer
Arquivos principais:

- `lib/src/features/feed/presentation/feed_screen.dart`
- possivelmente `lib/src/features/feed/presentation/widgets/feed_header.dart`
- novas telas/widgets de stories
- `lib/src/routing/route_paths.dart`
- `lib/src/routing/app_router.dart`

Entregas:

- bandeja de stories
- ring visto/não visto
- viewer full-screen
- navegação entre stories do mesmo autor e autores seguintes
- pause/resume e preload de imagem

### Phase 4. Author flows
Arquivos principais:

- `lib/src/features/profile/presentation/profile_screen.dart`
- nova `create_story_screen.dart`

Entregas:

- CTA para publicar story
- seleção de mídia
- preview antes de publicar
- exclusão do próprio story

### Phase 5. Video stories
Dependências:

- transcode dedicado ou reutilização segura do pipeline de galeria
- thumbnail consistente
- timeout/retry
- definição de duração máxima

Recomendação:
- limitar a 15 segundos
- adiar para depois de validar o MVP de imagem

### Phase 6. Observability and hardening
Entregas:

- eventos de analytics
- logging no `AppLogger`
- budget alerts no Firebase/Google Cloud
- métricas de erro e latência
- rate limiting para publicação e views

## Test plan

### Flutter
- unit tests do `story_repository`
- unit tests de ordenação/expiração
- widget tests da bandeja
- widget tests do viewer com avanço automático e pause
- widget tests do fluxo de criação

### Backend
- tests de Functions para expiração e recálculo de `story_state`
- tests de rules para leitura/escrita indevida
- validação de cleanup de Storage

### Manual QA
- publicar imagem
- expirar story
- ver story bloqueado/não elegível
- abrir viewer a partir do feed
- trocar de autor
- apagar story pelo autor
- validar reconnect / app cold start

## Engineering effort estimate
Estimativa para 1 dev com contexto no projeto:

- MVP imagem-only: 8 a 12 dias úteis
- MVP imagem + viewers list + cleanup robusto: 12 a 16 dias úteis
- adicionar vídeo curto com transcode e thumbnail: +4 a 7 dias úteis
- replies via chat + push + moderação adicional: +4 a 6 dias úteis

Estimativa prática:
- versão boa para produção sem vídeo: cerca de 2 a 3 semanas
- versão com vídeo e mais paridade: cerca de 3 a 5 semanas

## Infra cost assessment
Custos checados em fontes oficiais em 2026-03-10.

### 1. Billing plan requirement
Cloud Storage for Firebase exige projeto no plano Blaze para manter acesso ao bucket a partir de 2026-02-03.

Impacto:
- se o projeto ainda não estiver em Blaze, isso vira pré-requisito para stories
- se já estiver em Blaze por causa das Functions e uploads atuais, não é novo bloqueio

### 2. Firestore cost profile
O custo de metadata tende a ser baixo comparado à mídia.

Referências úteis:
- free tier do Firestore: 50k reads/dia, 20k writes/dia, 20k deletes/dia
- preço single-region visto na tabela oficial: aproximadamente
  - `$0.03 / 100k reads`
  - `$0.09 / 100k writes`
  - `$0.01 / 100k deletes`

Implicação:
- se o app gravar uma view por story, Firestore continua barato na maioria dos cenários de MVP
- viewers list é mais sensível a writes do que a reads

### 3. Storage cost profile
Armazenamento parado tende a ser barato.

Referência oficial observada:
- Standard Storage single-region em grupo de regiões que inclui `us-central1` e `southamerica-east1`: cerca de `$0.02 / GiB-mês`

Implicação:
- manter stories por 24h quase não pesa em storage at-rest
- o problema financeiro principal não é guardar o arquivo, e sim entregá-lo muitas vezes

### 4. Egress / bandwidth
Este é o principal driver de custo.

Referência oficial observada:
- outbound data transfer para usuários finais em destinos globais comuns: cerca de `$0.08 / GiB`

Implicação:
- histórias leves e bem comprimidas são decisivas
- vídeo cresce custo muito mais rápido do que Firestore

### 5. Cloud Functions / scheduler
Referências oficiais observadas:

- Cloud Run functions request-based tem free tier de `2 million requests/mês`
- Cloud Scheduler custa `$0.10` por job/mês, com `3 jobs` grátis por billing account

Implicação:
- cleanup agendado não pesa quase nada
- Functions de sincronização/cleanup não devem ser o centro do custo no MVP

### 6. Video transcode
Referência oficial observada:

- Transcoder API:
  - SD: `$0.015/min`
  - HD: `$0.030/min`

Implicação:
- vídeo é o segundo maior driver de custo depois de bandwidth
- para MVP, imagem-only é muito mais previsível financeiramente

## Example monthly scenarios
Valores abaixo são aproximações de ordem de grandeza, não orçamento fechado.

### Scenario A. Pilot image-only
- `100` stories por dia
- `5.000` views por dia
- payload médio entregue: `0.3 MB`

Estimativa:
- egress: ~`45 GB/mês` -> ~`US$ 3.60/mês`
- Firestore: tende a ficar dentro ou muito perto do free tier específico de stories
- Storage at-rest: desprezível

### Scenario B. Growing image usage
- `500` stories por dia
- `50.000` views por dia
- payload médio entregue: `0.3 MB`

Estimativa:
- egress: ~`450 GB/mês` -> ~`US$ 36/mês`
- Firestore writes extras de view continuam baixos perto do custo de mídia

### Scenario C. Video-heavy rollout
- `200` vídeo stories por dia
- `20.000` views por dia
- payload médio entregue: `2 MB`
- duração média: `15 s`

Estimativa:
- egress: ~`1.2 TB/mês` -> ~`US$ 96/mês`
- transcode HD: ~`1.500 min/mês` -> ~`US$ 45/mês`
- total de stories passa fácil de `US$ 140/mês` sem contar outras features do app

Conclusão:
- stories de imagem são baratos
- stories com vídeo podem ficar caros rápido

## Blockers and risks

### No hard blocker for MVP
Com o código atual, não vejo bloqueio estrutural para um MVP bem recortado.

### Real blockers if unresolved
1. Definição de audiência
   - o app não tem follower graph
   - sem decidir quem aparece na bandeja, o backend fica indefinido
2. Plano Blaze / billing ativo
   - obrigatório para continuar usando Cloud Storage
3. Política de vídeo
   - vídeo aumenta custo, complexidade de transcode e risco de moderação
4. Regras de visibilidade
   - precisa decidir como bloquear stories entre usuários bloqueados ou invisíveis
5. Full Instagram parity
   - stickers, música, menções, editor rico e highlights não cabem em um MVP curto

### Recommended scope guardrails
- lançar primeiro com imagem-only
- replies via chat só na segunda etapa
- viewers list pode entrar no MVP, mas sem analytics excessivo
- usar o feed atual como origem da bandeja

## Final recommendation
Se a meta for colocar stories no ar com risco controlado, o melhor caminho é:

1. MVP imagem-only
2. bandeja baseada no feed atual
3. cleanup server-side
4. `story_state` resumido no documento do usuário
5. vídeo só depois de medir uso e custo

Esse caminho entrega uma experiência claramente "stories" sem transformar a feature em re-arquitetura social do app.

## Sources checked on 2026-03-10
- Firebase Storage Blaze requirement: https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024
- Firestore pricing and free tier: https://firebase.google.com/docs/firestore/pricing
- Google Cloud Firestore operation pricing: https://cloud.google.com/firestore/pricing
- Google Cloud Storage pricing: https://cloud.google.com/storage/pricing
- Cloud Run functions pricing: https://cloud.google.com/run/pricing
- Cloud Scheduler pricing: https://cloud.google.com/scheduler/pricing
- Transcoder API pricing: https://cloud.google.com/transcoder/pricing
