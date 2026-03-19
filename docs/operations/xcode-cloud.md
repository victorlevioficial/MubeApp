# Xcode Cloud

Guia rapido para deixar o Mube publicavel via Xcode Cloud.

## O que o repositorio ja cobre

- Bundle ID configurado: `com.mube.mubeoficial`
- Signing automatico com `DEVELOPMENT_TEAM = 454U7QW5Q5`
- Scheme compartilhado: `Runner`
- Build phase do Crashlytics presente no target iOS
- Bootstrap Flutter no clone limpo via `ios/ci_scripts/ci_post_clone.sh`

## O que o workflow do Xcode Cloud precisa

Na configuracao do workflow, use:

- Action principal: `Archive`
- Distribution preparation:
  - `TestFlight Internal Testing Only` se o objetivo inicial for apenas validar com a equipe
  - `TestFlight and App Store` se voce quer manter aberta a opcao de teste externo depois
- Post-action recomendada para o primeiro fluxo: `TestFlight Internal Testing`

Importante:

- o Xcode Cloud pode publicar a build no TestFlight, mas a associacao da build a grupos internos ainda deve ser conferida no App Store Connect
- se voce optar por teste externo depois, precisara preencher `Test Information` e a primeira build enviada para externo passara por Beta App Review
- se o export do archive falhar com mensagens como `Failed to find an account with App Store Connect access for team`, `Unable to authenticate with App Store Connect`, `Automatic signing cannot update bundle identifier` ou `No profiles for 'com.mube.mubeoficial' were found`, o problema e o acesso da conta Apple usada pelo Xcode Cloud ao App Store Connect, nao o bootstrap Flutter
- nesse caso, reconecte a conta correta no Xcode Cloud/App Store Connect e execute `Clean and Rebuild`; o `archive` pode compilar normalmente e falhar so no `exportArchive`

## Variaveis de ambiente do workflow

Opcional:

- `IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64`

O script `ios/ci_scripts/ci_post_clone.sh` tambem aceita estes aliases:

- `GOOGLE_SERVICE_INFO_PLIST_BASE64`
- `GOOGLE_SERVICE_INFO_BASE64`

O valor deve ser o `base64` em linha unica de `ios/Runner/GoogleService-Info.plist`.
Se o secret nao existir, o bootstrap usa o fallback versionado em `ios/Runner/GoogleService-Info.ci.plist`.

Recomendada para paridade com producao:

- `GOOGLE_MAPS_API_KEY`

Opcionais:

- `GOOGLE_VISION_API_KEY`
- `FLUTTER_STORAGE_BASE_URL`
- `PUB_HOSTED_URL`

Observacao:

- `GOOGLE_MAPS_API_KEY` deve ser configurada para que a build publicada tenha localizacao, geocoding e autocomplete funcionando normalmente.
- sem `GOOGLE_MAPS_API_KEY`, o archive continua, mas esses fluxos ficam degradados nesse build.
- `GOOGLE_VISION_API_KEY` nao impede o archive, mas alguns fluxos de moderacao ficam degradados sem ela.
- a versao do Flutter nao deve ser configurada manualmente no workflow. O script do Xcode Cloud resolve a versao oficial a partir de `.fvmrc`, que e a fonte unica de verdade do repositorio.
- se `storage.googleapis.com` falhar no ambiente da Apple, o bootstrap faz retry automatico usando `https://storage.flutter-io.cn` e `https://pub.flutter-io.cn`, a menos que o workflow ja defina `FLUTTER_STORAGE_BASE_URL` ou `PUB_HOSTED_URL`.

## O que o script faz no clone limpo

`ios/ci_scripts/ci_post_clone.sh`:

1. instala o Flutter no ambiente do Xcode Cloud
2. restaura `ios/Runner/GoogleService-Info.plist` a partir do secret
3. roda `flutter pub get`
4. roda `pod install --repo-update`
5. roda `flutter build ios --config-only --release --no-codesign --no-pub`

Observacao importante:

- para projeto Flutter com pasta iOS separada, o Xcode Cloud precisa encontrar o hook em `ios/ci_scripts/ci_post_clone.sh`
- neste repositorio, esse arquivo apenas encaminha a execucao para o script central em `ci_scripts/ci_post_clone.sh`

Isso gera os artefatos que nao ficam versionados no repo e que o Xcode Cloud precisa, como:

- `ios/Flutter/Generated.xcconfig`
- `ios/Flutter/flutter_export_environment.sh`
- integracao CocoaPods sincronizada para o archive

## Pendencias fora do repositorio

Estas configuracoes ainda precisam existir fora do codigo para o pipeline ser publicavel:

- Apple Developer / App Store Connect:
  - a conta Apple conectada ao Xcode Cloud precisa ter acesso valido ao App Store Connect para o time `454U7QW5Q5`; sem isso, o export automatico nao consegue criar/selecionar provisioning profiles
  - o app ID `com.mube.mubeoficial` precisa estar com Signing automatico valido
  - Push Notifications deve estar habilitado, porque o app declara `aps-environment`
  - Sign in with Apple deve estar habilitado, porque o app declara esse entitlement
- App Store Connect / TestFlight:
  - criar ao menos um grupo de teste interno
  - associar o workflow ao app correto
- Firebase:
  - App Check do app iOS deve estar configurado para producao, porque o app ativa `AppleAppAttestWithDeviceCheckFallbackProvider()` em release
  - se voce quiser usar App Attest alem do fallback para DeviceCheck, habilite a capability correspondente no app ID e conclua a configuracao recomendada pelo Firebase

## Checklist curto

- secret `IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64` salvo no workflow
- workflow com `Archive`
- post-action de `TestFlight Internal Testing`
- grupo interno criado no TestFlight
- App Check do iOS configurado no Firebase
- capabilities do app ID conferidas no Apple Developer
