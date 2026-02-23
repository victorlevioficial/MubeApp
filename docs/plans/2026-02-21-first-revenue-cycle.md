# Primeiro Ciclo de Receita (Free vs Pro) - Implementation Plan

> **Para execucao:** usar `executing-plans` por lotes de tarefas e checkpoint semanal.

**Goal:** lancar o primeiro ciclo de receita recorrente do Mube com plano `Free` vs `Pro`, paywall in-app, fluxo de upgrade funcional e medicao confiavel de conversao.

**Architecture:** o ciclo de receita sera implementado com gating de features no app Flutter, entitlement de plano persistido em `users.plan`, controle de exposicao via Remote Config e validacao server-side por Cloud Functions. Conversao sera otimizada por funil (signup -> onboarding -> paywall -> checkout -> subscription_active) com experimento controlado.

**Tech Stack:** Flutter + Riverpod + GoRouter + Firebase (Auth, Firestore, Functions, Analytics, Remote Config) + Stripe (checkout/subscription/webhooks).

---

## 1) Skills usadas por etapa

1. `product-manager-toolkit`
2. `pricing-strategy`
3. `startup-metrics-framework`
4. `startup-financial-modeling`
5. `startup-business-analyst-financial-projections`
6. `analytics-tracking`
7. `signup-flow-cro`
8. `onboarding-cro`
9. `paywall-upgrade-cro`
10. `ab-test-setup`
11. `stripe-integration`
12. `billing-automation`
13. `firebase`
14. `flutter-expert`
15. `plan-writing`
16. `writing-plans`
17. `executing-plans`
18. `flutter-testing`
19. `production-code-audit`
20. `security-auditor`
21. `security-scanning-security-dependencies`
22. `observability-engineer`
23. `performance-engineer`
24. `launch-strategy`
25. `app-store-optimization`

---

## 2) KPIs oficiais do ciclo (90 dias)

| KPI | Baseline | Meta 90d |
|---|---:|---:|
| Onboarding completion | 0% | >= 70% |
| Activation rate | N/A | >= 45% |
| D7 retention | N/A | >= 20% |
| Free -> Pro conversion (MAU) | 0% | >= 2.5% |
| MRR | R$0 | >= R$6.000 |

---

## 3) Escopo

### In
- Packaging Free vs Pro
- Paywall e upgrade flow in-app
- Assinatura funcional (sandbox -> prod)
- Instrumentacao completa do funil de receita
- A/B tests em onboarding/paywall
- Gating tecnico seguro (sem update client-side de `plan`)

### Out
- Marketplace transacional completo
- Rankeamento com IA
- API publica para parceiros

---

## 4) Matriz de decisao Go/No-Go do MVP

### 4.1) Bloqueia lancamento (obrigatorio antes de abrir para publico)

| Area | Criterio objetivo | Skill principal | Evidencia minima |
|---|---|---|---|
| Entitlement e seguranca de plano | `users.plan` so pode ser alterado pelo backend | `firebase`, `security-auditor` | `firestore.rules` validada + tentativa client-side bloqueada em teste |
| Billing ponta a ponta | Fluxo `paywall -> checkout -> webhook -> users.plan=pro` com confiabilidade >= 95% em sandbox | `stripe-integration`, `billing-automation` | 20 execucoes E2E sandbox com taxa de sucesso >= 95% |
| Medicao confiavel do funil | Eventos core com cobertura >= 95% e sem duplicidade critica | `analytics-tracking` | Checklist de eventos + validacao manual/QA de tracking |
| Qualidade do fluxo critico | Sem bug P0/P1 aberto em signup, onboarding, paywall e checkout | `flutter-testing`, `production-code-audit` | Suite de testes passando + triagem de severidade atualizada |
| Estabilidade minima de producao | Crash-free sessions >= 99.5% no rollout inicial | `observability-engineer`, `performance-engineer` | Dashboard de crash/perf ativo + alertas configurados |
| Operacao e resposta a incidente | Runbook e plano de rollout progressivo definidos | `launch-strategy` | Documento de rollout `5% -> 25% -> 50% -> 100%` e runbook publicado |

### 4.2) Pode ajustar depois do lancamento (com monitoramento)

| Area | O que pode ficar para depois | Skill principal | Trigger de revisao |
|---|---|---|---|
| Copy e layout do paywall | Ordem de beneficios, CTA e variacoes de copy | `paywall-upgrade-cro`, `ab-test-setup` | Queda de `paywall_viewed -> checkout_started` por 2 semanas |
| Friccao de onboarding | Microajustes de UX, ordem de perguntas e mensagens | `onboarding-cro`, `signup-flow-cro` | Onboarding completion < meta por 2 semanas |
| Preco e trial | Ajustes de preco, desconto e duracao de trial | `pricing-strategy`, `startup-financial-modeling` | Conversao abaixo da meta ou payback fora do limite |
| Otimizacao de funil | Novos experimentos apos baseline estavel | `analytics-tracking`, `ab-test-setup` | Baseline estavel por 14 dias |
| Crescimento organico de loja | ASO, screenshots e metadata de loja | `app-store-optimization` | CPI alto ou baixa conversao de store |
| Planejamento financeiro avancado | Recalibrar cenario conservador/base/otimista | `startup-business-analyst-financial-projections`, `startup-metrics-framework` | Fechamento do primeiro ciclo mensal de receita |

### 4.3) Regra de decisao

1. Go-live apenas com 100% dos itens de `4.1` em verde.
2. Itens de `4.2` entram no backlog com dono, metrica e data de revisao.
3. Se qualquer item de `4.1` regredir durante rollout, pausar aumento de trafego.

---

## 5) Roadmap por fases (13 semanas)

## Fase 0 (Semana 1) - Strategic Lock

**Objetivo:** travar decisoes de monetizacao antes de implementar.

**Deliverables**
- PRD de monetizacao aprovado
- Matriz Free vs Pro aprovada
- Preco inicial e trial definidos
- Metricas e guardrails aprovados

**Tasks**
- [ ] Consolidar proposta de valor por persona (`musico`, `banda`, `estudio`, `contratante`).
- [ ] Definir value metric principal (ex.: limite de likes/contatos/visibilidade).
- [ ] Definir embalagem de planos (`Free`, `Pro`) com regras de gating explicitas.
- [ ] Definir politica de trial (sem trial, 7 dias, 14 dias) com criterio de escolha.
- [ ] Definir preco inicial e hipoteses de ajuste.
- [ ] Definir North Star + KPIs de receita e guardrails.
- [ ] Definir eventos obrigatorios do funil de receita.
- [ ] Publicar PRD final no repositorio.

**Arquivos (planejados)**
- Criar: `docs/monetization/prd-free-vs-pro.md`
- Criar: `docs/monetization/pricing-matrix.md`
- Criar: `docs/monetization/kpi-scorecard.md`

**Gate de saida**
- `pricing`, `trial`, `gating` e `KPIs` aprovados por PM + Tech Lead.

---

## Fase 1 (Semanas 2-3) - Measurement Foundation

**Objetivo:** garantir dados confiaveis antes de otimizar conversao.

**Deliverables**
- Taxonomia de eventos AARRR publicada
- Tracking de funil de receita ativo
- Dashboard Activation + Revenue v1

**Tasks**
- [ ] Unificar analytics service (eliminar duplicidade entre `core/services/analytics_service.dart` e `core/services/analytics/analytics_service.dart`).
- [ ] Definir naming convention de eventos e propriedades.
- [ ] Implementar eventos de `signup_started`, `signup_completed`.
- [ ] Implementar eventos de `onboarding_started`, `onboarding_completed`.
- [ ] Implementar eventos de `paywall_viewed`, `upgrade_cta_clicked`.
- [ ] Implementar eventos de `checkout_started`, `checkout_completed`.
- [ ] Implementar eventos de `subscription_started`, `subscription_renewed`, `subscription_canceled`.
- [ ] Adicionar feature flags de monetizacao em Remote Config.
- [ ] Documentar plano de medicao e ownership.

**Arquivos (alvo)**
- Modificar: `lib/src/core/services/analytics/analytics_service.dart`
- Modificar: `lib/src/core/services/analytics/analytics_provider.dart`
- Modificar: `lib/src/core/services/remote_config_service.dart`
- Criar: `docs/analytics/revenue-funnel-events.md`

**Gate de saida**
- Entrega de eventos core >= 95% e baseline de funil disponivel.

---

## Fase 2 (Semanas 3-5) - Signup + Onboarding CRO

**Objetivo:** elevar ativacao para preparar conversao paga.

**Deliverables**
- Signup com menos friccao
- Onboarding orientado para first value
- 1 experimento A/B ativo em onboarding

**Tasks**
- [ ] Mapear pontos de drop-off no signup atual.
- [ ] Reduzir campos obrigatorios na entrada.
- [ ] Ajustar copy e expectativa de tempo no cadastro.
- [ ] Revisar fluxo de selecao de tipo de perfil.
- [ ] Inserir progress feedback claro no onboarding.
- [ ] Definir e instrumentar evento de `first_value_action`.
- [ ] Configurar variante A/B de onboarding com hipotese e MDE travados.
- [ ] Medir impacto em completion e activation.

**Arquivos (alvo)**
- Modificar: `lib/src/features/auth/presentation/register_screen.dart`
- Modificar: `lib/src/features/onboarding/presentation/onboarding_type_screen.dart`
- Modificar: `lib/src/features/onboarding/presentation/onboarding_form_screen.dart`
- Modificar: `lib/src/features/onboarding/presentation/onboarding_controller.dart`
- Modificar: `lib/src/routing/auth_guard.dart`

**Gate de saida**
- Onboarding completion >= 70% (ou tendencia clara de alta por 2 semanas).

---

## Fase 3 (Semanas 5-7) - Paywall + Upgrade UX

**Objetivo:** converter valor percebido em intencao de compra.

**Deliverables**
- Paywall v1 in-app
- Triggers de upgrade por contexto
- Comparativo Free vs Pro dentro do app

**Tasks**
- [ ] Definir gatilhos de paywall (limite atingido, recurso premium, momento de valor).
- [ ] Criar tela de paywall com proposta de valor e comparacao clara.
- [ ] Exibir CTA de upgrade em Settings e pontos de uso.
- [ ] Implementar fallback para continuar no plano free sem friccao.
- [ ] A/B testar copy e ordem de beneficios.
- [ ] Integrar flags de oferta/experimento via Remote Config.

**Arquivos (alvo)**
- Criar: `lib/src/features/subscription/presentation/paywall_screen.dart`
- Criar: `lib/src/features/subscription/presentation/subscription_controller.dart`
- Criar: `lib/src/features/subscription/domain/plan_entitlement.dart`
- Modificar: `lib/src/routing/route_paths.dart`
- Modificar: `lib/src/routing/app_router.dart`
- Modificar: `lib/src/features/settings/presentation/widgets/bento_header.dart`

**Gate de saida**
- Taxa `paywall_viewed -> checkout_started` dentro da meta definida no PRD.

---

## Fase 4 (Semanas 6-9) - Billing + Entitlements

**Objetivo:** ativar receita real com fluxo de assinatura seguro.

**Deliverables**
- Checkout e assinatura em sandbox
- Webhooks processando status de subscription
- Entitlement `plan=pro` atualizado server-side
- Fluxo de cancelamento/dunning documentado

**Tasks**
- [ ] Criar produtos e precos na Stripe (test mode).
- [ ] Implementar endpoint/function para criar checkout session.
- [ ] Implementar webhooks com verificacao de assinatura e idempotencia.
- [ ] Persistir estado de subscription por usuario no Firestore.
- [ ] Atualizar `users.plan` somente por backend.
- [ ] Bloquear update client-side do campo `plan`.
- [ ] Implementar fluxo de expiracao/cancelamento e retorno para free.
- [ ] Implementar auditoria de eventos financeiros.
- [ ] Executar suite de testes sandbox fim-a-fim.

**Arquivos (alvo)**
- Criar: `functions/src/billing.ts`
- Modificar: `functions/src/index.ts`
- Modificar: `firestore.rules`
- Modificar: `lib/src/features/auth/data/auth_remote_data_source.dart`
- Modificar: `lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart`

**Gate de saida**
- Compra teste -> `subscription_started` -> `users.plan=pro` sem intervencao manual.

---

## Fase 5 (Semanas 9-11) - Monetization Optimization

**Objetivo:** elevar conversao com experimentacao disciplinada.

**Deliverables**
- 2 a 3 testes A/B concluidos
- Relatorio por experimento com decisao
- Guardrails de churn/retencao/suporte monitorados

**Tasks**
- [ ] Rodar experimento #1 (copy de paywall).
- [ ] Rodar experimento #2 (trigger timing).
- [ ] Rodar experimento #3 (oferta/tier emphasis).
- [ ] Monitorar guardrails (`D7`, churn precoce, tickets de suporte).
- [ ] Consolidar aprendizados em playbook de conversao.

**Arquivos (planejados)**
- Criar: `docs/experiments/2026-q1-paywall-tests.md`
- Criar: `docs/experiments/2026-q1-onboarding-tests.md`

**Gate de saida**
- Pelo menos 1 melhoria estatisticamente valida aplicada em producao.

---

## Fase 6 (Semanas 11-12) - Finance Calibration

**Objetivo:** recalibrar previsao com dados reais e preparar proximo ciclo.

**Deliverables**
- Modelo financeiro v2 (realizado vs previsto)
- Recomendacao de ajuste de preco/trial
- Plano Q+1 de monetizacao

**Tasks**
- [ ] Atualizar cohort model com dados reais de ativacao e conversao.
- [ ] Recalcular CAC/LTV/payback.
- [ ] Atualizar cenarios conservador/base/otimista.
- [ ] Propor ajustes de preco, trial e packaging.
- [ ] Priorizar backlog de Q+1 com RICE.

**Arquivos (planejados)**
- Criar: `docs/monetization/financial-model-v2.md`
- Criar: `docs/monetization/q2-pricing-recommendations.md`

**Gate de saida**
- Plano Q+1 aprovado com metas e hipoteses claras.

---

## Fase 7 (Semana 13) - Hardening + Controlled Rollout

**Objetivo:** estabilizar, reduzir risco operacional e escalar rollout.

**Deliverables**
- Testes de integracao para jornada de assinatura
- Rollout progressivo com monitoramento
- Runbook de incidentes de billing

**Tasks**
- [ ] Adicionar testes de integracao de funil de compra.
- [ ] Definir rollout 5% -> 25% -> 50% -> 100%.
- [ ] Definir alertas para falhas de checkout/webhook.
- [ ] Preparar runbook para falhas de entitlement.
- [ ] Revisar suporte/FAQ para novo plano Pro.

**Arquivos (alvo)**
- Criar: `integration_test/subscription_flow_test.dart`
- Modificar: `lib/src/features/support/data/faq_data.dart`
- Criar: `docs/runbooks/billing-incidents.md`

**Gate de saida**
- Conversao e estabilidade dentro dos thresholds definidos no scorecard.

---

## 6) Mudancas tecnicas obrigatorias (bloqueadores)

1. Bloquear update client-side de `users.plan` em `firestore.rules`.
2. Remover `plan` de payload de update no cliente (`auth_remote_data_source`) quando update for client-driven.
3. Definir source of truth do entitlement no backend (Cloud Functions + webhook Stripe).
4. Unificar camada de analytics para evitar eventos duplicados/inconsistentes.

---

## 7) Backlog inicial (Sprint 1 executavel)

- [ ] Criar PRD de monetizacao (`docs/monetization/prd-free-vs-pro.md`).
- [ ] Criar matriz Free vs Pro (`docs/monetization/pricing-matrix.md`).
- [ ] Definir taxonomia de eventos de receita (`docs/analytics/revenue-funnel-events.md`).
- [ ] Unificar analytics service.
- [ ] Adicionar flags de monetizacao em Remote Config.
- [ ] Criar esqueleto de `features/subscription`.
- [ ] Especificar contrato de webhook e entitlement no backend.
- [ ] Abrir testes de integracao para funil de upgrade (arquivo placeholder).

---

## 8) Riscos e mitigacoes

1. **Risco:** instrumentacao incompleta leva a decisao errada.  
**Mitigacao:** fase 1 obrigatoria com QA de tracking e event delivery gate.

2. **Risco:** usuario alterar `plan` no cliente.  
**Mitigacao:** bloquear em rules + atualizar somente backend.

3. **Risco:** atraso em billing/store review.  
**Mitigacao:** iniciar sandbox cedo e rollout por flag.

4. **Risco:** aumento de churn por paywall agressivo.  
**Mitigacao:** guardrails + A/B + frequencia de trigger controlada.

---

## 9) Cadencia de execucao

- Review de KPI: semanal, mesmo dia e hora.
- Review de experimento: quinzenal.
- Checkpoint de fase: fim de cada fase com go/no-go documentado.
- Status report: sempre com `baseline -> atual -> delta -> decisao`.

---

## 10) Definicoes pendentes (precisam ser travadas antes da Fase 4)

1. Preco inicial do Pro (mensal/anual).
2. Trial (sim/nao e duracao).
3. Stack final de billing (`Stripe direto` vs `store-native` vs `hibrido`).
4. Beneficio premium principal para upgrade imediato (gating primario).
