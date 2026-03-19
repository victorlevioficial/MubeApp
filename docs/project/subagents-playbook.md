# Subagents Playbook

Guia rapido para usar subagents no AppMube sem criar conflito entre arquivos.

## Objetivo

No AppMube, subagent bom e subagent com escopo pequeno, leitura minima e ownership claro de arquivos.

A regra principal e:

- um agente escreve routing
- um agente escreve a feature
- um agente escreve testes
- design system entra como dono de `lib/src/design_system/**` ou como revisor

## Perfis Criados

Os perfis do projeto foram adicionados em `.agent/agents/`:

- `appmube-orchestrator`
- `appmube-routing-reviewer`
- `appmube-feature-worker`
- `appmube-design-system-guard`
- `appmube-test-writer`

Se a ferramenta que voce usa le `.agent/agents`, esses perfis ja podem virar base de execucao.
Se estiver falando direto com o Codex, use os prompts abaixo e cite o perfil como foco do subagent.

## Atalho Unico

Agora o projeto tambem tem um atalho operacional:

- workflow: `.agent/workflows/appmube-package.md`
- skill local: `.agents/skills/appmube-package/SKILL.md`

Objetivo:

- permitir um prompt curto como `Use o pacote AppMube neste task: ...`
- aplicar automaticamente o read order, ownership por caminho e guardrails do projeto

## Prompt Mais Curto Possivel

```text
Use o pacote AppMube neste task: <descreva a tarefa>
```

Se quiser deixar mais deterministico, use:

```text
Use o pacote AppMube neste task: <descreva a tarefa>.
Se a tarefa for grande, delegue em paralelo com ownership exclusivo por caminho.
```

## Matriz de Ownership

| Perfil | Pode escrever | Nao deve escrever | Use quando |
| --- | --- | --- | --- |
| `appmube-routing-reviewer` | `lib/src/routing/**`, `lib/src/app.dart` quando houver impacto de navegacao | `test/**`, logica de feature fora do necessario | rota nova, redirect, deep link, shell |
| `appmube-feature-worker` | `lib/src/features/<feature>/**` | `lib/src/routing/**`, `test/**`, outras features | implementacao principal da tarefa |
| `appmube-design-system-guard` | `lib/src/design_system/**` ou UI atribuida explicitamente | arquivos de negocio e testes | auditoria visual, tokens, componentes |
| `appmube-test-writer` | `test/**` | `lib/**` | cobertura de regressao, widget, unit, routing |

## Ordem Recomendada

1. Ler `AGENTS.md`.
2. Ler `lib/src/app.dart`.
3. Ler `lib/src/routing/app_router.dart`.
4. Ler `lib/src/routing/route_paths.dart`.
5. Ler a feature alvo.
6. Se tocar UI, ler `lib/src/design_system/`.
7. So depois dividir a tarefa entre subagents.

## Regras que Evitam Conflito

- Nao deixe dois workers editarem `lib/src/routing/app_router.dart`.
- Nao deixe dois workers editarem `lib/src/app.dart`.
- Nao deixe o test writer editar producao.
- Nao deixe o feature worker inventar rota hardcoded se `RoutePaths` deve ser atualizado.
- Nao deixe nenhum agente editar `*.g.dart` ou `*.freezed.dart`.
- Nao deixe o design-system guard abrir ownership amplo em `lib/src/features/**` se outro worker ja estiver na mesma tela.

## Prompt Base Para Codex

Use este modelo quando quiser delegacao no AppMube:

```text
Use subagents neste task e respeite o AppMube:
1. Todo agente deve ler AGENTS.md, lib/src/app.dart, lib/src/routing/app_router.dart e lib/src/routing/route_paths.dart antes de concluir.
2. Nao deixe dois workers editarem o mesmo arquivo.
3. Preserve o padrao local da feature, Riverpod existente, RoutePaths, AppLogger e design system.
4. Nao edite arquivos gerados.
```

## Como O Pacote Decide A Divisao

- Se a tarefa for pequena, ele nao precisa forcar subagents.
- Se houver impacto em routing, sobe `appmube-routing-reviewer`.
- Se houver UI relevante, sobe `appmube-design-system-guard` como revisor ou dono de `lib/src/design_system/**`.
- Se houver comportamento alterado, sobe `appmube-test-writer` para manter o teste separado da producao.

## Prompt Pronto: Nova Feature Em Uma Area Existente

```text
Use 3 subagents neste task.
1. Um explorer com foco de appmube-routing-reviewer para mapear impacto em RoutePaths, GoRouter e shell navigation. Sem editar arquivos.
2. Um worker com foco de appmube-feature-worker para implementar apenas em lib/src/features/gigs/**.
3. Um worker com foco de appmube-test-writer para ajustar apenas test/widget/gigs/** e test/unit/gigs/**.
Nao deixe dois workers editarem o mesmo arquivo. Preserve o padrao local da feature, AppLogger, Riverpod existente e design system.
```

## Prompt Pronto: Mudanca De Rota

```text
Use 2 subagents neste task.
1. Um worker com foco de appmube-routing-reviewer para ser dono de lib/src/routing/** e de lib/src/app.dart somente se houver impacto de bootstrap ou push navigation.
2. Um explorer para validar a feature afetada e apontar riscos de redirect, parametros de rota e tela destino.
Nao deixe nenhum outro worker editar arquivos de routing.
```

## Prompt Pronto: Refactor Visual

```text
Use 3 subagents neste task.
1. Um explorer com foco de appmube-design-system-guard para auditar tokens, componentes compartilhados e inconsistencias visuais na feature profile.
2. Um worker com foco de appmube-feature-worker para implementar apenas em lib/src/features/profile/**.
3. Um worker com foco de appmube-test-writer para atualizar testes de widget em test/widget/profile/**.
Se o design system precisar mudar, mova a ownership de lib/src/design_system/** para um unico worker e nao compartilhe esses arquivos.
```

## Prompt Pronto: Bug Em Side Effect Ou Listener

```text
Use 3 subagents neste task.
1. Um explorer para investigar lifecycle, ref.listenManual, bootstrap em app.dart e impacto de navegacao.
2. Um worker com foco de appmube-feature-worker para corrigir apenas a feature afetada.
3. Um worker com foco de appmube-test-writer para escrever regressao no menor escopo possivel.
Se houver impacto em routing, promova um unico dono para lib/src/routing/** e mantenha a feature fora desses arquivos.
```

## Quando Nao Vale A Pena

Evite subagents quando:

- a mudanca cabe em um arquivo
- voce ainda nao sabe qual feature sera afetada
- o problema esta em arquivos gerados
- a tarefa e so leitura ou so uma resposta conceitual

## Checklist Rapido Antes De Delegar

- O write scope de cada agente esta definido por caminho?
- Ha um unico dono para routing?
- Ha um unico dono para testes?
- A feature worker ficou restrita a uma feature?
- O design-system guard vai revisar ou escrever?
- O prompt cita `AGENTS.md`, `RoutePaths`, Riverpod local e `AppLogger`?
