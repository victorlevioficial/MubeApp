# Relatório de Auditoria — MubeApp v1.1.4

Data: 2026-03-04
Skills: flutter-expert, flutter-architecture, production-code-audit, clean-code

---

## Resumo Executivo

O MubeApp possui base sólida: feature-first, Riverpod 3, design system, error boundary,
logging, performance tracking e boa cobertura de testes unitários/widget.
Este relatório foi revisado para refletir o código real do repositório em 2026-03-04.
Alguns pontos abaixo são problemas objetivos; outros são recomendações arquiteturais.

| Categoria           | Nota | Issues |
|---------------------|------|--------|
| Arquitetura         | B    | 5      |
| Error Handling      | C+   | 4      |
| Tipagem/Null Safety | C    | 3      |
| Performance         | B+   | 3      |
| Testes              | B-   | 4      |
| Seguranca           | B    | 2      |
| UI/UX Code Quality  | B+   | 3      |
| Infra/DevOps        | B+   | 2      |

Nota geral: B

---

## CRITICOS (Corrigir Primeiro)

### 1. God Classes nos Repositorios

Arquivos com 500+ linhas e responsabilidades demais:

- lib/src/features/feed/data/feed_repository.dart — 795 linhas
  18+ metodos, queries geo, filtros, paginacao, normalizacao — tudo junto.
  Dividir em: FeedQueryService + FeedGeoService + FeedPaginationService

- lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart — 834 linhas
  Scoring, geohash, Cloud Functions, parsing — responsabilidades misturadas.
  Dividir em: MatchpointCandidateService + MatchpointScoringEngine + MatchpointInteractionService

- lib/src/features/chat/data/chat_repository.dart — 515 linhas
  CRUD + parsing + preview logic + transaction tudo no mesmo arquivo.

- lib/src/features/auth/data/auth_repository.dart — 532 linhas
  Auth + perfil + analytics + security context — muitas responsabilidades.

- lib/src/routing/app_router.dart — 407 linhas
  Funcao _buildRoutes() monolitica com 330 linhas.
  Separar em funcoes por feature (auth routes, main shell, profile, etc.)

### 2. catch (e) Generico — Ocorrencias Reais Relevantes

Existem diversos blocos `catch` genéricos no projeto. Isso dificulta diagnóstico
e, em alguns fluxos, reduz a qualidade do mapeamento de falhas.

Arquivos mais afetados:
- storage_repository.dart — 9 catches genericos
- matchpoint_repository.dart — 8 catches genericos
- edit_profile_controller.dart — 7 catches genericos
- moderation_repository.dart — 3 catches genericos

Correcao:

```dart
// RUIM
} catch (e) {
  AppLogger.error('Erro', e);
  return Left(UnknownFailure());
}

// BOM
} on FirebaseException catch (e, stack) {
  AppLogger.error('Firebase error', e, stack);
  return Left(FailureMapper.fromFirebase(e));
} on TimeoutException catch (e, stack) {
  AppLogger.warning('Timeout', e, stack);
  return Left(NetworkFailure.timeout());
} catch (e, stack) {
  AppLogger.error('Unexpected error', e, stack);
  return Left(UnexpectedFailure(originalError: e, stackTrace: stack));
}
```

### 3. Uso Excessivo de dynamic — 57 Arquivos Nao Gerados

Ha uso amplo de `dynamic` e `Map<String, dynamic>` fora de arquivos gerados.
Parte disso e esperada em fronteiras com Firestore, Cloud Functions e JSON, mas
ha casos que poderiam ser mais bem encapsulados com tipagem forte.

Correcao:
- Criar data classes Freezed para respostas Firestore
- Usar fromJson/toJson com tipagem forte
- Auditar cada uso e separar boundary types de dynamic evitavel

---

## ALTA PRIORIDADE

### 4. Tratamento de Erro e Fluxos Assincronos em Widgets

Ha widgets com `try/catch` local. Nem todos configuram "logica de negocio" de fato:
alguns apenas tratam interacoes de UI, picker de midia ou feedback visual.
Ainda assim, alguns fluxos podem ser simplificados se a camada de controller absorver
mais responsabilidade de erro.

- create_ticket_screen.dart — catch local para `ImagePicker`; submissao principal ja usa controller
- edit_profile_screen.dart — error handling inline
- favorites_screen.dart — catch generico na tela
- invites_screen.dart — 2 catches genericos
- media_gallery_section.dart — catches de picker/processamento e feedback na UI

Correcao: mover para controllers apenas o que for regra de negocio, persistencia,
orquestracao ou mapeamento de falha. Manter na UI apenas interacoes locais de widget.

### 5. Domain Layer Inconsistente

Nem todas features seguem data/domain/presentation:

| Feature    | domain/ | data/ | Consistente |
|------------|---------|-------|-------------|
| auth       | sim     | sim   | sim         |
| feed       | sim     | sim   | sim         |
| chat       | sim     | sim   | sim         |
| matchpoint | sim     | sim   | sim         |
| gallery    | nao     | nao   | NAO         |
| admin      | nao     | nao   | NAO         |
| developer  | nao     | nao   | NAO         |

Observacao: `admin/` e `developer/` existem como features com pasta `presentation/`,
mas estao sem arquivos no estado atual. `gallery/` contem uma tela utilitaria de showcase
do design system. O ponto aqui e inconsistencia estrutural, nao necessariamente erro funcional.

Correcao: decidir explicitamente quais features sao placeholders/experimentos e quais devem
seguir o padrao `data/domain/presentation`.

### 6. Falta de Use Cases

O projeto nao declara formalmente, nos arquivos centrais, uma exigencia de MVVM + Clean Architecture
com use cases dedicados. Ainda assim, alguns fluxos complexos poderiam ganhar clareza se fossem
extraidos para classes de orquestracao explicitas.

Correcao: Para fluxos complexos (ex: sendMessage que atualiza preview + metadata
+ incrementa unread), considerar use cases/servicos de aplicacao quando a orquestracao
entre repositorios crescer demais.

---

## MEDIA PRIORIDADE

### 7. Testes — Lacunas

Estrutura existente (boa):
- test/unit/ — 58 itens
- test/widget/ — 39 itens
- test/integration/ — 6 itens
- test/routing/ — 1 item

Lacunas:
- Existem testes para storage_repository.dart
- Existem testes para moderation_repository.dart
- Existem testes de Cloud Functions no projeto Flutter
- Cobertura de integration tests baixa (apenas 6 arquivos)
- Sem golden tests para o design system

Detalhe:
- `test/unit/features/storage/storage_repository_test.dart`
- `test/unit/features/moderation/moderation_repository_test.dart`
- `test/unit/features/matchpoint/matchpoint_remote_data_source_test.dart`
- `test/unit/features/invites/invites_repository_test.dart`

### 8. Linting Poderia Ser Mais Rigido

analysis_options.yaml usa flutter_lints (base). Regras ausentes recomendadas:

```yaml
# Tipagem
- always_specify_types
- avoid_dynamic_calls
- strict_raw_type

# Seguranca
- close_sinks
- no_adjacent_strings_in_list
- prefer_void_to_null

# Qualidade
- avoid_catches_without_on_clauses  # Detecta catch generico!
- avoid_returning_null_for_future
```

### 9. Strings Hardcoded em Failures

lib/src/core/errors/failures.dart contem ~30 mensagens em portugues hardcoded.
App tem l10n (pt/en) mas mensagens de erro nao passam pelo sistema de localization.

Correcao: Mover mensagens para app_pt.arb / app_en.arb e usar AppLocalizations.

### 10. Delay em Servicos Deferidos no Bootstrap

lib/main.dart linha 184:

```dart
await Future<void>.delayed(const Duration(milliseconds: 2100));
```

Esse delay existe, mas nao bloqueia o bootstrap principal do app. Ele roda em
`_initializeDeferredServices()` depois que `_firebaseReady` ja foi marcado e a app tree
ja comecou a renderizar. O problema aqui nao e "2.1s a mais no carregamento inicial",
e sim o uso de espera fixa para postergar warmup de servicos.

Correcao: se esse warmup precisar ser mais deterministico, usar trigger por evento,
idle frame ou heuristica mais explicita.

---

## BAIXA PRIORIDADE

### 11. Provider Legacy vs Generator

Projeto mistura providers manuais (Provider<T>((ref) {...})) com generators (@riverpod).
Isso e verdadeiro no estado atual. Ainda assim, migrar tudo nao e obrigatoriamente prioridade:
ha providers simples em que `Provider`/`StreamProvider` continuam adequados.

Correcao: padronizar criterios de uso, em vez de migrar tudo indiscriminadamente.

### 12. common_widgets/ vs design_system/

Pasta common_widgets/ com 2 arquivos existe separada do design_system/ (62 itens).
O ponto de inconsistencia e real, mas `location_service.dart` e um servico, nao um componente
de design system. Entao a migracao nao deve ser automatica para `design_system/components/`.

Correcao: mover formatters/servicos para pastas semanticas corretas (`shared/`, `utils/`,
`core/` ou feature adequada), nao necessariamente para o design system.

### 13. Firestore Cache Size Unlimited

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

Cache ilimitado pode consumir memoria excessiva em dispositivos com pouco storage.
Considerar limite razoavel (ex: 100MB).

---

## PONTOS POSITIVOS (Manter)

- Feature-first architecture — Organizacao por features bem definida
- Riverpod 3 + Generators — State management moderno
- Design System centralizado — Tokens, componentes, tema
- Error Boundary no bootstrap — Captura erros globais
- AppLogger (nao print) — 0 prints em producao
- Performance Tracker — Spans de performance no bootstrap
- Firestore Constants centralizados — Sem strings inline
- RoutePaths centralizados — Sem rotas hardcoded
- Result pattern (fpdart) — Either<Failure, T> nos repositories
- Testes existentes — Unit, widget, integration, routing
- Dark theme consistente — AppTheme.darkTheme centralizado
- Push bootstrap inteligente — Respeita permissao do onboarding

---

## PLANO DE ACAO

### Sprint 1 — Error Handling (2-3 dias)
- [ ] Tipar todos os catch (e) genericos com excecoes especificas
- [ ] Mover para controllers apenas erros de negocio/persistencia; manter catches locais de UI quando fizer sentido
- [ ] Adicionar regra avoid_catches_without_on_clauses ao linter

### Sprint 2 — God Classes (3-5 dias)
- [ ] Dividir feed_repository.dart em 3 classes
- [ ] Dividir matchpoint_remote_data_source.dart em 3 classes
- [ ] Dividir _buildRoutes() em funcoes por feature

### Sprint 3 — Tipagem e Consistencia (2-3 dias)
- [ ] Reduzir dynamic evitavel e encapsular melhor fronteiras com Firestore/JSON
- [ ] Padronizar criterios para providers manuais vs @riverpod
- [ ] Reorganizar common_widgets/ para pastas semanticas corretas
- [ ] Localizar strings de failures.dart

### Sprint 4 — Testes (3-4 dias)
- [ ] Golden tests para design system
- [ ] Aumentar integration tests
- [ ] Expandir cenarios de storage/moderation/matchpoint ja cobertos
