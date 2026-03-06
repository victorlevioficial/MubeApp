# AGENTS.md - Mube App

Guia operacional para agentes de IA trabalharem no Mube com contexto rapido e confiavel.

## Objetivo

Use este arquivo como mapa inicial do projeto.
Para detalhes, siga sempre os arquivos-fonte citados aqui. Eles sao a fonte da verdade.

## Resumo do App

- App Flutter para conectar musicos, bandas, estudios e contratantes no Brasil
- Stack principal: Flutter, Dart 3.8+, Firebase, Riverpod, GoRouter
- Tema atual: dark only
- Idioma ativo na interface: `pt`
- Infra de localizacao para `en` existe, mas nao esta em circulacao no app

Arquivos-chave:

- App root: `lib/main.dart`
- App widget: `lib/src/app.dart`
- Router: `lib/src/routing/app_router.dart`
- Route paths: `lib/src/routing/route_paths.dart`
- Design system: `lib/src/design_system/`
- Core config data: `lib/src/core/`
- Features: `lib/src/features/`

## Como Entender o Projeto Rapido

Em praticamente toda tarefa, leia nesta ordem:

1. `lib/src/app.dart`
2. `lib/src/routing/app_router.dart`
3. `lib/src/routing/route_paths.dart`
4. A feature alvo em `lib/src/features/{feature}`
5. Se houver UI, consulte `lib/src/design_system/` antes de criar algo novo

Para contexto adicional:

- Visao geral do projeto: `README.md`
- Governanca de dependencias: `docs/dependency-governance.md`
- Testes: `test/README.md`
- Arquitetura e indices: `CODE_INDEX.md`, `ARCHITECTURE.md`, `docs/architecture-spec.md`
- Design system atual: `docs/reference/design-system-current.md`
- Code style: `docs/reference/code-style.md`

## Estrutura Real do Projeto

```text
lib/
  main.dart
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

Observacoes importantes:

- O projeto e feature-based, mas nem toda feature segue exatamente `data/domain/presentation`
- Algumas features tambem usam `providers/`, `controllers/`, `screens/` e `widgets/`
- Nao assuma uniformidade total; confirme na feature real antes de editar

## Convenções Reais do App

### Idioma

- Codigo: ingles
- Comentarios tecnicos: ingles
- Strings de UI: preferencialmente portugues
- Respostas do agente ao usuario: sempre em portugues do Brasil, salvo pedido explicito em outro idioma
- Arquivos: `snake_case`

### State Management

Padrao atual:

- Riverpod 3
- Uso frequente de `@riverpod`, `NotifierProvider` e `AsyncNotifierProvider`
- Ainda pode existir provider manual ou legado; siga o padrao local da feature

Arquivos de referencia:

- `lib/src/core/providers/app_config_provider.dart`
- `lib/src/features/support/presentation/support_controller.dart`
- `lib/src/features/auth/data/auth_repository.dart`

Regras:

- Antes de criar provider novo, procure um provider existente da feature
- Nao trate `StateNotifierProvider` como padrao automatico do projeto
- Nunca edite arquivos gerados manualmente: `*.g.dart`, `*.freezed.dart`

### Navegação

Padrao atual:

- GoRouter centralizado em `lib/src/routing/app_router.dart`
- Constantes de rotas em `lib/src/routing/route_paths.dart`
- Shell navigation em `StatefulShellRoute.indexedStack`

Regras:

- Use `RoutePaths`, nunca strings hardcoded quando ja houver constante
- Antes de adicionar rota, veja como a feature esta conectada ao shell atual

### Design System

Padrao atual:

- Tokens em `lib/src/design_system/foundations/tokens/`
- Tema em `lib/src/design_system/foundations/theme/`
- Componentes compartilhados em `lib/src/design_system/components/`

Regras:

- Nao hardcode cor, raio, espacamento ou tipografia se houver token existente
- Reuse componentes existentes antes de criar widget novo
- Confira primeiro:
  - `app_colors.dart`
  - `app_typography.dart`
  - `app_spacing.dart`
  - `app_radius.dart`
  - `app_motion.dart`

Observacao:

- O codigo atual usa `AppColors.background`, `AppColors.surface` e derivados
- Nao assuma nomes antigos de token sem confirmar no arquivo real

### Logging e Erros

Arquivos de referencia:

- Logger: `lib/src/utils/app_logger.dart`
- Failures/errors: `lib/src/core/errors/`
- Firebase/auth error handling: `lib/src/utils/auth_exception_handler.dart`

Regras:

- Nao use `print`
- Use a API real do logger: `AppLogger.debug`, `info`, `warning`, `error`, `fatal`
- Antes de criar excecao custom nova, veja se a feature ja trabalha com `Failure`, `AsyncValue.guard` ou handler utilitario

### Firebase e Constantes

Arquivos de referencia:

- Firebase options: `lib/firebase_options.dart`
- Firestore constants: `lib/src/constants/firestore_constants.dart`

Regras:

- Nao invente nomes de collection/field no codigo
- Reuse constantes existentes sempre que houver

## Testes

Estrutura real relevante:

```text
test/
  helpers/
  integration/
  routing/
  src/
  unit/
  widget/
```

Comandos uteis:

- `./scripts/analyze_app.sh`
- `flutter test`
- `flutter test test/unit/`
- `flutter test test/widget/`
- `flutter test test/integration/`
- `flutter test --coverage`

Regras:

- Ao alterar comportamento, procure testes da feature antes de escrever do zero
- Reuse helpers de `test/helpers/`

## Ambiente Hibrido Windows/Linux

Observacao importante:

- Este projeto pode ser aberto tanto no Windows quanto no Linux/WSL
- O diretorio `.dart_tool/` e gerado com caminhos absolutos do ambiente atual
- Ao alternar entre Windows e Linux, o analyzer, `dart` ou `flutter` podem falhar porque o `package_config.json` anterior fica invalido no outro sistema

Regra operacional:

- Se houver erro de resolucao de pacotes apos trocar de ambiente, rode `flutter pub get` no ambiente atual antes de continuar
- Nao trate `.dart_tool/package_config.json` como fonte de verdade portavel entre sistemas

## Fluxo Recomendado para Qualquer Tarefa

1. Ler a feature alvo
2. Confirmar o padrao local de provider/controller/widget
3. Confirmar rotas e dependencias compartilhadas
4. Reusar design system e constantes
5. Rodar teste focado primeiro, depois escopo maior se necessario

## O Que Nao Assumir

- Que toda feature tenha exatamente `data/domain/presentation`
- Que todo estado use `StateNotifierProvider`
- Que exemplos antigos de rota, logger ou widget de erro ainda existam
- Que um nome de token visto em documentacao antiga ainda esteja valido

## Checklist Antes de Editar

- A API usada existe de fato no projeto atual?
- Ja existe componente, provider ou constante para isso?
- A feature possui padrao proprio que deve ser preservado?
- Ha arquivo gerado que nao deve ser editado manualmente?
- Existe teste proximo ao codigo alterado?

## Conclusão Operacional

Este app e entendivel rapidamente, desde que a leitura inicial parta dos arquivos centrais e da feature alvo, nao de exemplos genericos.
Use este `AGENTS.md` como indice curto; use o codigo real como autoridade final.

Ultima revisao: 2026-03-04
