# Mube

Aplicativo Flutter para conectar musicos, bandas, estudios e contratantes no Brasil.

## Visao Geral

Principais areas do app:

- Autenticacao
- Perfis
- Feed
- Busca
- MatchPoint
- Chat
- Favoritos
- Notificacoes
- Suporte

Stack principal:

- Flutter 3.8+
- Dart 3.8+
- Firebase
- Riverpod 3
- GoRouter

Contratos tecnicos atuais importantes:

- `RoutePaths` e `GoRouter` sao a fonte da verdade de navegacao
- rotas publicas incluem caminhos dinamicos como `/legal/:type`
- perfis `professional`, `band` e `studio` nao expõem nome de registro em superficies publicas quando faltam nomes publicos
- listeners de efeito colateral em telas sensiveis devem ser registrados fora de `build`, via lifecycle + `ref.listenManual(...)`
- o bootstrap inicial remove o splash nativo somente depois de o app ter estado visual valido

## Estrutura do Projeto

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

test/
  helpers/
  integration/
  routing/
  src/
  unit/
  widget/
```

Observacoes:

- O projeto e feature-based
- Nem toda feature segue exatamente `data/domain/presentation`
- Algumas features usam `providers/`, `controllers/`, `screens/` e `widgets/`

## Pontos de Entrada Importantes

- App bootstrap: `lib/main.dart`
- App widget: `lib/src/app.dart`
- Router: `lib/src/routing/app_router.dart`
- Route paths: `lib/src/routing/route_paths.dart`
- Design system: `lib/src/design_system/`
- Firestore constants: `lib/src/constants/firestore_constants.dart`

Ordem recomendada de leitura para entender o projeto:

1. `lib/main.dart`
2. `lib/src/app.dart`
3. `lib/src/routing/app_router.dart`
4. `lib/src/routing/route_paths.dart`
5. a feature alvo em `lib/src/features/`

## Setup

Pre-requisitos:

- Flutter SDK `>=3.8.0`
- Dart SDK `>=3.8.0`
- Android Studio e/ou Xcode
- Projeto Firebase configurado

Instalacao:

```bash
flutter pub get
flutter run
```

Configuracao:

- chaves e flags de ambiente devem vir de `--dart-define` quando aplicavel
- nao confie em fallback implicito de chaves de terceiros a partir de config do Firebase

Firebase:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## Build

Android:

```bash
flutter build apk --release
flutter build appbundle --release
```

Deploy Play Store com Fastlane:

```bash
bundle install
export PLAY_STORE_JSON_KEY="$PWD/android/fastlane/play-store-service-account.json"
bundle exec fastlane android closed
```

iOS:

```bash
flutter build ios --release
```

Guias relacionados:

- `docs/operations/build-guide.md`
- `docs/windows-mac-ios-workflow.md`

## Testes

Comandos uteis:

```bash
flutter analyze
flutter test
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
flutter test --coverage
```

Referencia:

- `test/README.md`

Status esperado do workspace:

- `flutter analyze` limpo
- `flutter test` verde

## Convenções

- Codigo em ingles
- Strings de UI preferencialmente em portugues
- Arquivos em `snake_case`
- Nao use `print`; use `AppLogger`
- Reuse tokens e componentes do design system antes de criar novos
- Use `RoutePaths` em vez de rotas hardcoded
- Antes de criar provider novo, verifique o padrao local da feature
- Nao registre listeners de side effect dentro de `build` quando eles precisarem sobreviver a rebuilds

## Documentacao de Referencia

Fonte de verdade atual:

- Arquitetura: `ARCHITECTURE.md`
- Indice tecnico: `CODE_INDEX.md`
- Spec complementar: `docs/architecture-spec.md`
- Design system atual: `docs/reference/design-system-current.md`
- Code style: `docs/reference/code-style.md`
- Firestore schema: `docs/FIRESTORE_SCHEMA.md`
- Regras de negocio: `docs/business-rules-catalog.md`
- Estado geral do projeto: `docs/project/status.md`
- Build e operacao: `docs/operations/build-guide.md`

## Internacionalizacao

Idiomas suportados:

- `pt` (padrao)
- `en`

## Projeto

- Pacote: `mube`
- Versao atual: `1.1.3+12`
- Repositorio privado

Ultima revisao: 2026-03-04
