# Testes - Mube

## Estrutura real

```text
test/
  helpers/         # pumpApp, fakes, dados de teste e utilitarios Firebase
  integration/     # fluxos multi-camada por feature
  routing/         # testes diretos de contrato de rotas
  src/             # suites legadas ou focadas em data layer
  unit/            # logica pura, controllers, repositories e providers
  widget/          # UI isolada por feature e design system
```

Diretorios hoje usados com frequencia:

- `test/helpers/`
- `test/integration/auth/`
- `test/integration/profile/`
- `test/integration/search/`
- `test/unit/auth/`
- `test/unit/features/`
- `test/unit/routing/`
- `test/widget/auth/`
- `test/widget/design_system/`
- `test/widget/features/`
- `test/widget/matchpoint/`

## Como rodar

Todos os testes:

```bash
flutter test
```

Suites principais:

```bash
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
flutter test test/routing/
```

Arquivos ou areas especificas:

```bash
flutter test test/unit/auth/
flutter test test/widget/features/search/
flutter test test/integration/profile/profile_flow_test.dart
```

Com cobertura:

```bash
flutter test --coverage
```

Validacao complementar:

```bash
flutter analyze
```

## Helpers principais

### `test/helpers/pump_app.dart`

Use para montar widgets com `MaterialApp`, localizacao e overrides de providers.

```dart
await tester.pumpApp(const MyWidget());

await tester.pumpApp(
  const MyWidget(),
  overrides: [myProvider.overrideWithValue(mockValue)],
);
```

### `test/helpers/test_fakes.dart`

Contem fakes reutilizaveis para repositories e servicos usados em widget e unit tests.

Exemplos comuns:

- `FakeAuthRepository`
- `FakeFavoriteRepository`
- `FakeFeedRepository`
- `FakeChatRepository`

### `test/helpers/test_data.dart`

Factories para montar entidades de teste sem duplicar payloads longos.

Exemplos comuns:

- `TestData.user(...)`
- `TestData.feedItem(...)`
- `TestData.conversationPreview(...)`

### `test/helpers/firebase_mocks.dart`

Mocks e utilitarios para cenarios com Firebase Auth/Core em suites de integracao.

## Convencoes atuais

- Nome de arquivo: `{arquivo}_test.dart`
- Organize cenarios com `group()`
- Prefira descricao objetiva em ingles, por exemplo `renders`, `loads`, `navigates`, `handles`
- Use padrao AAA quando o teste nao ficar artificial
- Ao mudar comportamento de uma feature, procure primeiro testes proximos antes de criar uma suite nova
- Reaproveite `test/helpers/` antes de introduzir doubles locais

## Contratos importantes do projeto

- `RoutePaths` e `GoRouter` sao a fonte da verdade de navegacao
- Perfis `professional`, `band` e `studio` nao devem expor nome de registro como fallback em superficies publicas; muitos testes verificam esse contrato
- Rotas publicas dinamicas como `/legal/:type` fazem parte do contrato atual
- Fluxos sensiveis a rebuild passaram a usar `ref.listenManual(...)` fora de `build` em telas como app, search e chat
- O bootstrap inicial agora mostra loading visual real antes de remover o splash nativo

## Status atual

- `flutter analyze` deve permanecer limpo
- `flutter test` esta verde na revisao de `2026-03-04`
