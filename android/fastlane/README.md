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

2. Salve o JSON da conta de servico, por exemplo:

```text
android/fastlane/play-store-service-account.json
```

3. Exporte a variavel de ambiente antes do deploy:

```bash
export PLAY_STORE_JSON_KEY="$PWD/android/fastlane/play-store-service-account.json"
```

Tambem e aceito `SUPPLY_JSON_KEY`.

4. Rode o Fastlane dentro de `android/`:

```bash
cd android
bundle exec fastlane android closed
```

## Lanes

Comandos abaixo executados a partir de `android/`:

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

Se sua track fechada tiver outro nome no Google Play Console:

```bash
export PLAY_STORE_CLOSED_TRACK="nome-da-sua-track"
bundle exec fastlane android closed
```

Deploy para producao:

```bash
bundle exec fastlane android production
```

Somente validacao no Google Play:

```bash
bundle exec fastlane android production validate_only:true
```

## WSL em `/mnt/c` (opcional)

Se o Bundler falhar por permissao de `vendor/bundle` (`world-writable`), rode:

```bash
BUNDLE_IGNORE_CONFIG=1 BUNDLE_PATH="$HOME/.bundle_mube" bundle install
cd android
BUNDLE_IGNORE_CONFIG=1 BUNDLE_PATH="$HOME/.bundle_mube" bundle exec fastlane android closed
```

## Observacoes

- O bundle e gerado com `flutter build appbundle --release`
- A lane nao envia metadata, screenshots nem imagens da Play Store
- `versionName` e `versionCode` continuam vindo do `pubspec.yaml`
