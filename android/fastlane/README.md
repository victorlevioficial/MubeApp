# Fastlane Android

Automacao de deploy para Google Play usando App Bundle (`.aab`) gerado pelo Flutter.

## Pre-requisitos

1. Ruby e Bundler instalados
2. `flutter pub get` executado ao menos uma vez
3. Keystore Android configurado em `android/key.properties`
4. Conta de servico do Google Play Console com permissao de release

## Setup

1. Instale as gems:

```bash
bundle install
```

2. Salve o JSON da conta de servico em um caminho local, por exemplo:

```text
android/fastlane/play-store-service-account.json
```

3. Exporte a variavel de ambiente antes do deploy:

```bash
export PLAY_STORE_JSON_KEY="$PWD/android/fastlane/play-store-service-account.json"
```

Se preferir, use `SUPPLY_JSON_KEY`, que tambem e aceita.

## Lanes

Deploy para teste interno:

```bash
bundle exec fastlane android internal
```

Deploy para track beta/closed testing:

```bash
bundle exec fastlane android beta
```

Deploy para teste fechado:

```bash
bundle exec fastlane android closed
```

Por padrao, essa lane envia para a track `alpha`.

Se sua track fechada tiver outro nome no Google Play Console, exporte:

```bash
export PLAY_STORE_CLOSED_TRACK="nome-da-sua-track"
```

Deploy para producao:

```bash
bundle exec fastlane android production
```

Opcionalmente, envie apenas para validacao no Google Play:

```bash
bundle exec fastlane android production validate_only:true
```

## Wrapper recomendado (raiz do repo)

Para reduzir erros de ambiente, rode pela raiz:

```bash
scripts/release_android.sh closed
```

Esse wrapper:
- valida `PLAY_STORE_JSON_KEY`/`SUPPLY_JSON_KEY`;
- valida se o arquivo JSON existe;
- valida keystore do `android/key.properties` e aplica fallback automatico quando o arquivo estiver em `android/app/`.

## Observacoes

- O bundle e gerado com `flutter build appbundle --release`
- A lane nao envia metadata, screenshots nem imagens da Play Store
- `versionName` e `versionCode` continuam vindo do `pubspec.yaml`
- Versao atual configurada no projeto: `1.1.4+13`
