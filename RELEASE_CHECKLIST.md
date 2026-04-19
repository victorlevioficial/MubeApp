# Release Checklist — Mube

Processo para promover o app através das trilhas **alpha → beta → GA** (produção pública). O objetivo é reduzir risco de regressão e garantir que toda release passe pelo mesmo gate.

> **Convenção de commit**: só commits com prefixo `chore(release):` em `main` disparam a publicação na Play Store. Merges de PR (`Merge pull request #N...`) **não** disparam — sempre criar commit dedicado de bump após merge.

---

## Antes de qualquer release

Execute o script de validação:

```bash
./scripts/preflight.sh           # completo (format + analyze + tests)
./scripts/preflight.sh --quick   # só format + analyze (para iteração)
```

O script valida os mesmos gates que a CI mais 4 checks extras (versão bumped, arquivos gerados frescos, secrets scan, TODOs de bloqueio).

---

## Trilha 1 — Alpha (testers internos)

**Critério de entrada**: feature nova ou bugfix que precisa de validação em dispositivos reais antes de promover para tester externos.

- [ ] Feature branch mergeada em `main` via PR
- [ ] `./scripts/preflight.sh` verde
- [ ] `pubspec.yaml` com versão bumped (PATCH+BUILD: `1.6.36+184` → `1.6.37+185`)
- [ ] Commit: `chore(release): X.Y.Z+BUILD <descrição curta>`
- [ ] Push em `main` → CI roda → AAB publica em Play Console track `alpha`
- [ ] Verificar em Play Console que build chegou em `alpha` (~5-10 min após CI verde)
- [ ] Testar manualmente em device real:
  - [ ] Instalar via link de tester
  - [ ] Login (email/password + Google + Apple se iOS)
  - [ ] Feed carrega
  - [ ] Criar/editar perfil
  - [ ] Áreas afetadas pela mudança desta release

**Tempo típico em alpha**: 2-5 dias com pelo menos 1 teste de regressão manual.

---

## Trilha 2 — Beta (testers externos, até ~1000 pessoas)

**Critério de entrada**: alpha rodou sem crashes novos no Crashlytics por 48h+ e critérios funcionais foram validados.

- [ ] Crashlytics: nenhum issue crítico novo em 48h
- [ ] Analytics: eventos-chave estão sendo logados (ver seção de gaps abaixo)
- [ ] Aprovar rollout alpha → beta na Play Console
- [ ] Comunicar testers externos (grupo no WhatsApp/Discord/email)
- [ ] Abrir canal de feedback (form, email, ou equivalente)
- [ ] Aguardar 5-7 dias

**Checks durante beta**:
- [ ] Crash-free sessions > 99%
- [ ] ANR rate < 0.5%
- [ ] Feedback de usuários triado (bugs abertos em issues)

---

## Trilha 3 — GA / Produção pública

**Critério de entrada**: beta com 100+ instalações ativas, crash-free > 99%, sem bugs P0/P1 pendentes.

### Gaps conhecidos a resolver antes da GA (estado em 2026-04-18)

Estes foram identificados em auditoria e devem ser fechados **antes** de abrir para o público geral:

#### Observabilidade (Agent B — 2026-04-18)
- [ ] **Crashlytics**: OK (90% pronto). Validar que `recordError` está wired em todos os `catch` top-level.
- [ ] **Analytics gaps**: Adicionar `FirebaseAnalytics.logEvent` em:
  - [ ] `onboarding_complete`
  - [ ] `gig_create`, `gig_apply`
  - [ ] `story_publish`
  - [ ] `matchpoint_swipe`
  - [ ] `band_invite_sent`, `band_invite_accepted`
  - [ ] `share_profile`
- [ ] **AppLogger**: revisar `lib/src/features/settings/presentation/settings_screen.dart` — bloco `catch {}` vazio no fluxo de delete-account está engolindo erros.

#### Segurança / LGPD (Agent D — 2026-04-18)
- [ ] **Firestore rules**: rules atuais permitem enumeração em `/users` e `/bands`. Restringir leitura de listas (usar `resource.data.visibility == 'public'` ou query-shape enforcement).
- [ ] **LGPD export**: criar endpoint/fluxo para exportação de dados pessoais (direito de portabilidade — obrigatório por lei).
- [ ] **Retenção `deletedUsers`**: definir política de retenção para coleção de backup de usuários deletados (TTL ou Cloud Scheduler).
- [ ] **Política de privacidade** publicada e linkada em onboarding + settings.
- [ ] **Termos de uso** publicados e aceitos no cadastro.

#### Performance (Agent D — 2026-04-18)
- [ ] Trocar `NetworkImage` por `CachedNetworkImage` em:
  - [ ] `lib/src/features/feed/presentation/feed_screen.dart:288,296`
  - [ ] `lib/src/features/stories/presentation/story_viewer_screen.dart:129`
- [ ] Adicionar `.limit()` em query sem limite: `lib/src/features/bands/data/invites_repository.dart:247` (`getUserBands`)
- [ ] Adicionar `const` onde faltar (auditado via `flutter analyze`)

### Processo de release GA

- [ ] Todos os gaps acima fechados e documentados em PR
- [ ] `./scripts/preflight.sh` verde
- [ ] Rollout progressivo na Play Console: **10% → 25% → 50% → 100%**
  - [ ] Aguardar 24h entre cada degrau
  - [ ] Em cada degrau, verificar Crashlytics e reviews
  - [ ] Pausar rollout se crash-free < 99% ou se reviews < 4.0
- [ ] App Store Connect (iOS): submit for review com mesmo binário
- [ ] Anúncio público apenas após 100% rollout estar estável por 48h

---

## Rollback

Se algo der muito errado após release:

**Play Store (Android)**:
1. Play Console → Production → Releases → Create new release
2. Fazer upload do AAB anterior (ou usar a opção "Rollback" em App Bundle Explorer)
3. Pausar rollout atual em Google Play Console

**Server-side (Cloud Functions / Firestore rules)**:
```bash
# Reverter rules
git revert <hash-da-release-ruim>
./deploy-firestore.ps1

# Reverter função específica
.\deploy-functions.ps1 --only functions:<nome>
```

**Feature flag**: Para desligar feature problemática sem release, usar Firebase Remote Config (se a feature está gated por flag).

---

## Referências

- `CLAUDE.md` — processo de release detalhado (seção "Release Process")
- `.github/workflows/ci.yml` — gate de CI (format, analyze, test, build)
- `scripts/release_android.sh`, `scripts/release_ios.sh` — build manual
- `scripts/upload_play_store_release.mjs` — upload automatizado (usa `PLAY_STORE_SERVICE_ACCOUNT_JSON` como secret de repo)
- Firebase Console → Crashlytics / Analytics → monitorar saúde pós-release
