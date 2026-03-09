# Professional Category Split Plan

## Goal
Separar a categoria profissional legada `crew` em duas categorias canônicas:

- `production`
- `stage_tech`

Mantendo o app funcional durante a transição e evitando quebra em:

- onboarding
- edição de perfil
- feed
- busca
- perfis públicos
- config remota
- seeder
- Gigs
- dados legados já salvos no Firestore

## Product decisions assumed in this plan
- Categorias finais de profissional: `singer`, `instrumentalist`, `dj`, `production`, `stage_tech`.
- `production` recebe badge e tratamento de músico.
- `stage_tech` é a única categoria técnica pura.
- O campo Firestore `dadosProfissional.categorias` continua existindo.
- O campo Firestore `dadosProfissional.funcoes` continua sendo uma lista única.
- O campo de Gigs `required_crew_roles` permanece como está nesta fase por compatibilidade.

## Non-goals
- Não renomear `required_crew_roles` em Firestore.
- Não reestruturar `dadosProfissional.funcoes` em dois campos persistidos.
- Não remover todo o suporte legado a `crew` na mesma entrega.
- Não editar arquivos gerados manualmente; geração continua via `build_runner`.

## Why the original plan was insufficient
O plano inicial acertava a direção do produto, mas deixava riscos abertos:

- `SearchFilters` usaria enum names que não batem com `stage_tech`.
- `AppConfig.crewRoles` seria removido cedo demais, quebrando Gigs, providers e fallback config.
- perfis legados com `crew` ficariam ambíguos sem regra de classificação por função.
- havia superfícies ainda fora do escopo, como `filter_modal`, `active_filters_bar`, `profile_screen`, `app_seeder` e testes de integração já existentes.

## Current state confirmed in code
Hoje `crew` aparece como conceito persistido e/ou de UI em múltiplas camadas:

- Config estática em `lib/src/constants/app_constants.dart`
- Config remota em `lib/src/core/domain/app_config.dart`
- Providers em `lib/src/core/providers/app_config_provider.dart`
- Seeder e fallback config em `lib/src/core/data/app_seeder.dart` e `lib/src/core/data/app_config_repository.dart`
- Onboarding em `lib/src/features/onboarding/`
- Edição de perfil em `lib/src/features/profile/presentation/edit_profile/`
- Feed em `lib/src/features/feed/`
- Busca em `lib/src/features/search/`
- Gigs em `lib/src/features/gigs/`

Isso exige rollout compatível, não só rename direto.

## Data contract after rollout

### Firestore user document
`dadosProfissional.categorias`

- valores canônicos novos:
  - `singer`
  - `instrumentalist`
  - `dj`
  - `production`
  - `stage_tech`
- valor legado aceito em leitura durante transição:
  - `crew`

`dadosProfissional.funcoes`

- continua sendo `List<String>`
- contém IDs canônicos de função
- pode conter valores legados durante a transição

### App config
Adicionar em `AppConfig`:

- `productionRoles`
- `stageTechRoles`

Manter temporariamente:

- `crewRoles`

Regra:
- `crewRoles` vira lista compatível de união entre `productionRoles` e `stageTechRoles`
- Gigs e fluxos ainda não migrados podem continuar usando `crewRoles`

## Compatibility strategy
O app precisa suportar três estados ao mesmo tempo:

1. Perfis novos com `production` e `stage_tech`
2. Perfis antigos ainda com `crew`
3. Dados híbridos durante a janela de migração

Para isso, a leitura deve ser tolerante e a escrita deve ser canônica.

### Write path
Depois da entrega, o app passa a gravar apenas:

- `production`
- `stage_tech`

Nunca grava `crew` em novos saves.

### Read path
Leitura continua aceitando `crew`, mas a classificação deve usar as funções do perfil quando necessário.

Regra para legado `crew`:

- se as funções mapearem apenas para produção, tratar como `production`
- se as funções mapearem apenas para palco/técnica, tratar como `stage_tech`
- se houver mistura ou ambiguidade, não tratar como técnico puro

Essa regra evita classificar produtor antigo como técnico só porque ainda está com `crew`.

## New shared domain utility
Criar `lib/src/utils/category_normalizer.dart`.

Responsabilidades:

- `sanitize(String value)`
- `normalizeCategoryId(String raw)`
- `normalizeRoleId(String raw)`
- `resolveCategories({required List<String> rawCategories, required List<String> rawRoles})`
- `isPureTechnician({required List<String> rawCategories, required List<String> rawRoles})`

Mapeamentos mínimos:

- `production`, `producao_musical`, `produtor`, `produtor_musical` -> `production`
- `stage_tech`, `tecnica_de_palco`, `tecnico_de_palco`, `tecnico_pa` -> `stage_tech`
- `crew`, `equipe_tecnica`, `tecnico`, `tecnica` -> `crew` na normalização bruta

Observação importante:
- `crew` não deve ser convertido cegamente para `stage_tech`
- a resolução final depende das funções do perfil

## Remote config and constants plan

### 1. Static constants
Atualizar `lib/src/constants/app_constants.dart`:

- trocar categoria `crew` por `production` e `stage_tech`
- extrair:
  - `productionRoles`
  - `stageTechRoles`
- manter `crewRoles` como união compatível e marcar como legado de transição

### 2. AppConfig domain
Atualizar `lib/src/core/domain/app_config.dart`:

- adicionar `productionRoles`
- adicionar `stageTechRoles`
- manter `crewRoles` por compatibilidade nesta fase

Isso reduz risco de quebra em Gigs e em telas que ainda usam a lista agregada.

### 3. AppConfig repository and seeder
Atualizar:

- `lib/src/core/data/app_config_repository.dart`
- `lib/src/core/data/app_seeder.dart`
- `lib/src/core/providers/app_config_provider.dart`

Adicionar providers novos:

- `productionRoleLabelsProvider`
- `stageTechRoleLabelsProvider`

Manter:

- `crewRoleLabelsProvider`

Regra:
- `crewRoleLabelsProvider` retorna a união das listas novas durante a transição

## Flutter implementation phases

### Phase 1. Shared model and compatibility foundation
Objetivo: introduzir os novos conceitos sem quebrar telas existentes.

Arquivos principais:

- `lib/src/constants/app_constants.dart`
- `lib/src/core/domain/app_config.dart`
- `lib/src/core/data/app_config_repository.dart`
- `lib/src/core/data/app_seeder.dart`
- `lib/src/core/providers/app_config_provider.dart`
- `lib/src/utils/category_normalizer.dart`

Entregas:

- novas categorias e listas de função
- `AppConfig` com listas novas e compatibilidade em `crewRoles`
- normalizador compartilhado
- seeder gerando perfis com as novas categorias

### Phase 2. Onboarding and profile mutation
Objetivo: novos cadastros e edições passam a gravar categorias canônicas.

Arquivos principais:

- `lib/src/features/onboarding/presentation/onboarding_type_screen.dart`
- `lib/src/features/onboarding/presentation/steps/professional_category_step.dart`
- `lib/src/features/onboarding/presentation/flows/onboarding_professional_flow.dart`
- `lib/src/features/onboarding/presentation/onboarding_form_provider.dart`
- `lib/src/features/onboarding/presentation/onboarding_controller.dart`
- `lib/src/features/profile/presentation/edit_profile/controllers/edit_profile_controller.dart`
- `lib/src/features/profile/presentation/edit_profile/controllers/edit_profile_state.dart`
- `lib/src/features/profile/presentation/edit_profile/widgets/forms/professional_form_fields.dart`

Decisão de modelagem:

- o estado local de UI deve separar:
  - `selectedProductionRoles`
  - `selectedStageTechRoles`
- no save, combinar em um único `funcoes`

Validação:

- `production` exige ao menos uma função de produção
- `stage_tech` exige ao menos uma função técnica de palco
- `instrumentalist` continua exigindo instrumentos
- `selectedGenres` continua obrigatório

### Phase 3. Feed, public profile and classification
Objetivo: aplicar a nova taxonomia sem regressão em discovery.

Arquivos principais:

- `lib/src/features/feed/domain/feed_item.dart`
- `lib/src/features/feed/domain/feed_discovery.dart`
- `lib/src/features/feed/data/feed_repository.dart`
- `lib/src/features/feed/presentation/controllers/feed_main_controller.dart`
- `lib/src/features/feed/presentation/widgets/profile_type_badge.dart`
- `lib/src/features/profile/presentation/profile_screen.dart`
- `lib/src/features/profile/presentation/widgets/profile_hero_header.dart`
- `lib/src/features/feed/domain/feed_section.dart`

Regras:

- `production` conta como músico
- `stage_tech` conta como técnico
- `crew` legado deve ser resolvido pelas funções antes de determinar técnico puro

Resultado esperado:

- aba de artistas inclui `production`
- aba de técnicos mostra apenas `stage_tech` puro
- badge não marca produtor como técnico

### Phase 4. Search and filters
Objetivo: refletir as novas categorias em toda a superfície de busca.

Arquivos principais:

- `lib/src/features/search/domain/search_filters.dart`
- `lib/src/features/search/data/search_repository.dart`
- `lib/src/features/search/presentation/widgets/filter_modal.dart`
- `lib/src/features/search/presentation/widgets/active_filters_bar.dart`
- `lib/src/features/search/presentation/widgets/smart_prefilter_grid.dart`

Decisão obrigatória:
- `ProfessionalSubcategory` precisa expor um ID persistido, não depender de `.name`

Exemplo:

```dart
enum ProfessionalSubcategory {
  singer('singer'),
  instrumentalist('instrumentalist'),
  production('production'),
  stageTech('stage_tech'),
  dj('dj');

  const ProfessionalSubcategory(this.firestoreId);
  final String firestoreId;
}
```

Uso:
- filtros e repositório passam a comparar com `firestoreId`
- não usar `.name` para persistência

### Phase 5. Firebase migration
Objetivo: atualizar perfis antigos no backend sem depender do usuário editar perfil.

Implementar função de migração em `functions/src/` seguindo o padrão já usado pelas migrações existentes.

Comportamento:

1. buscar usuários com `dadosProfissional.categorias` contendo `crew`
2. ler `dadosProfissional.funcoes`
3. normalizar funções
4. derivar novas categorias:
   - produção somente -> `production`
   - palco/técnica somente -> `stage_tech`
   - mistura -> ambas
   - sem funções reconhecidas -> logar como ambíguo e não apagar `crew` automaticamente
5. gravar `categorias` novas
6. registrar métricas de:
   - migrados
   - ambíguos
   - sem função
   - já migrados

Recomendação:
- usar endpoint HTTP protegido por `MIGRATION_TOKEN`, igual às migrações existentes
- executar em dry-run primeiro

## Gigs compatibility decision
Gigs não devem bloquear esta entrega.

Nesta fase:

- `GigFields.requiredCrewRoles` permanece
- `Gig.requiredCrewRoles` permanece
- telas de Gigs continuam usando `config.crewRoles`
- `config.crewRoles` passa a ser a união de `productionRoles` e `stageTechRoles`

Benefício:
- a feature nova avança sem reestruturação paralela de Gigs

## File-by-file implementation checklist

### Config and utils
- [ ] Atualizar `lib/src/constants/app_constants.dart`
- [ ] Atualizar `lib/src/core/domain/app_config.dart`
- [ ] Atualizar `lib/src/core/data/app_config_repository.dart`
- [ ] Atualizar `lib/src/core/data/app_seeder.dart`
- [ ] Atualizar `lib/src/core/providers/app_config_provider.dart`
- [ ] Criar `lib/src/utils/category_normalizer.dart`

### Onboarding
- [ ] Atualizar `lib/src/features/onboarding/presentation/onboarding_type_screen.dart`
- [ ] Atualizar `lib/src/features/onboarding/presentation/steps/professional_category_step.dart`
- [ ] Atualizar `lib/src/features/onboarding/presentation/flows/onboarding_professional_flow.dart`
- [ ] Atualizar `lib/src/features/onboarding/presentation/onboarding_form_provider.dart`
- [ ] Ajustar persistência em `lib/src/features/onboarding/presentation/onboarding_controller.dart` se necessário

### Profile
- [ ] Atualizar `lib/src/features/profile/presentation/edit_profile/controllers/edit_profile_state.dart`
- [ ] Atualizar `lib/src/features/profile/presentation/edit_profile/controllers/edit_profile_controller.dart`
- [ ] Atualizar `lib/src/features/profile/presentation/edit_profile/widgets/forms/professional_form_fields.dart`
- [ ] Atualizar `lib/src/features/profile/presentation/profile_screen.dart`
- [ ] Atualizar `lib/src/features/profile/presentation/widgets/profile_hero_header.dart`

### Feed
- [ ] Atualizar `lib/src/features/feed/domain/feed_item.dart`
- [ ] Atualizar `lib/src/features/feed/domain/feed_discovery.dart`
- [ ] Atualizar `lib/src/features/feed/data/feed_repository.dart`
- [ ] Revisar `lib/src/features/feed/presentation/controllers/feed_main_controller.dart`
- [ ] Atualizar `lib/src/features/feed/presentation/widgets/profile_type_badge.dart`
- [ ] Revisar `lib/src/features/feed/domain/feed_section.dart`

### Search
- [ ] Atualizar `lib/src/features/search/domain/search_filters.dart`
- [ ] Atualizar `lib/src/features/search/data/search_repository.dart`
- [ ] Atualizar `lib/src/features/search/presentation/widgets/filter_modal.dart`
- [ ] Atualizar `lib/src/features/search/presentation/widgets/active_filters_bar.dart`
- [ ] Atualizar `lib/src/features/search/presentation/widgets/smart_prefilter_grid.dart`

### Functions
- [ ] Criar migração em `functions/src/`
- [ ] Exportar em `functions/src/index.ts`
- [ ] Adicionar teste de função se houver cobertura local viável

## Verification plan

### Automated tests
Adicionar ou adaptar:

- `test/unit/features/feed/domain/feed_discovery_test.dart`
- `test/unit/features/search/search_repository_test.dart`
- `test/unit/features/search/presentation/search_controller_test.dart`
- `test/unit/features/onboarding/presentation/onboarding_controller_test.dart`
- `test/widget/features/onboarding/presentation/onboarding_type_screen_test.dart`
- `test/widget/features/search/presentation/search_screen_test.dart`
- `test/unit/features/feed/presentation/feed_view_controller_test.dart`
- `test/integration/search/search_flow_test.dart`
- `test/integration/profile/profile_flow_test.dart`
- `test/unit/core/app_config_repository_test.dart` ou equivalente novo para config de domínio
- `test/unit/utils/category_normalizer_test.dart`

Observação:
- `test/unit/core/app_config_test.dart` não cobre `lib/src/core/domain/app_config.dart`; não deve ser usado como proxy dessa mudança

### Build and generation
Rodar:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test
cd functions && npm test && npm run build
```

Arquivos provavelmente afetados por geração:

- `lib/src/core/domain/app_config.dart`
- `lib/src/features/search/domain/search_filters.dart`
- `lib/src/features/feed/domain/feed_item.dart`
- `lib/src/features/profile/presentation/edit_profile/controllers/edit_profile_state.dart`

## Manual acceptance criteria
- [ ] Novo onboarding mostra 5 categorias profissionais
- [ ] Seleção de `production` exige função de produção
- [ ] Seleção de `stage_tech` exige função técnica de palco
- [ ] Perfil salvo novo nunca grava `crew`
- [ ] Perfil salvo com `production` aparece como músico no feed
- [ ] Perfil salvo com `stage_tech` puro aparece em técnicos
- [ ] Perfil misto `singer + production` continua em artistas
- [ ] Perfil legado `crew` com função de produção não é tratado como técnico puro
- [ ] Busca por subcategoria `production` funciona
- [ ] Busca por subcategoria `stage_tech` funciona
- [ ] Prefilters de produção e palco retornam resultados corretos
- [ ] Edição de perfil lê dados legados e salva dados novos corretamente
- [ ] Gigs continuam exibindo e selecionando funções via lista agregada
- [ ] Migração em dry-run reporta ambiguidades sem gravar alterações
- [ ] Migração real converte `crew` para categorias novas quando a classificação for segura

## Rollout order

1. Subir app compatível com leitura de legado e escrita nova
2. Validar em staging com perfis novos e perfis `crew` antigos
3. Executar migração em dry-run
4. Corrigir casos ambíguos se necessário
5. Executar migração real
6. Monitorar feed, busca e edição de perfil
7. Só depois avaliar remoção de compatibilidade com `crew`

## Cleanup phase after migration
Somente depois de validar produção:

- remover suporte legado a `crew` onde não for mais necessário
- decidir se `crewRoles` permanece como alias compatível ou sai do `AppConfig`
- revisar se `ProfessionalCategory` em `firestore_constants.dart` ainda faz sentido
- limpar testes e fixtures que ainda usam `crew` sem propósito de retrocompatibilidade

## Recommended implementation order

1. Config e normalizador compartilhado
2. Onboarding e edição de perfil
3. Feed e classificação
4. Busca e filtros
5. Seeder e fixtures
6. Migração backend
7. Testes de integração

## Summary
Este plano troca uma migração de rename simples por uma estratégia de compatibilidade progressiva. A chave para evitar regressões é:

- escrever apenas categorias novas
- continuar lendo `crew`
- classificar `crew` legado a partir de `funcoes`
- manter `crewRoles` como ponte temporária para Gigs e telas ainda agregadas
