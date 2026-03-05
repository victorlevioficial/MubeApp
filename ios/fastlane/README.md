# Fastlane iOS

Automacao de build e upload para TestFlight usando App Store Connect API Key.

## Pre-requisitos

1. macOS com Xcode instalado
2. Ruby e Bundler instalados
3. `bundle install` executado na raiz do projeto
4. Chave App Store Connect (`AuthKey_*.p8`) fora do repositorio

## Variaveis de ambiente

Exporte as variaveis abaixo antes de subir para TestFlight:

```bash
export ASC_KEY_ID="SEU_KEY_ID"
export ASC_ISSUER_ID="SEU_ISSUER_ID"
export ASC_KEY_FILEPATH="$HOME/.appstoreconnect/private_keys/AuthKey_XXXXXX.p8"
```

## Lanes

Gerar IPA de release (App Store):

```bash
bundle exec fastlane ios build_ipa
```

Fazer upload de um IPA existente para TestFlight:

```bash
bundle exec fastlane ios upload_testflight
```

Build + upload em um comando:

```bash
bundle exec fastlane ios beta
```

## Wrapper recomendado (raiz do repo)

Para reduzir erros de ambiente:

```bash
scripts/release_ios.sh build_ipa
scripts/release_ios.sh upload_testflight
scripts/release_ios.sh beta
```

## Observacoes

- O lane `build_ipa` usa `flutter build ipa --release --export-method app-store`
- O lane `upload_testflight` usa `pilot` com API key (sem login interativo Apple ID)
- O script valida `ASC_KEY_ID`, `ASC_ISSUER_ID` e `ASC_KEY_FILEPATH` antes do upload
