# Guia de Build - Mube App

Este guia contém instruções para gerar builds de release do aplicativo Mube.

## Pré-requisitos

### Android
- Android SDK instalado
- JDK 17 ou superior
- Keystore configurado (ver abaixo)

### iOS
- macOS com Xcode instalado
- Conta de desenvolvedor Apple ativa
- Certificados e provisioning profiles configurados

---

## Configuração Android

### 1. Keystore (Assinatura do App)

O app precisa ser assinado com um keystore para ser publicado na Play Store.

#### Criar um novo keystore (se necessário):
```bash
keytool -genkey -v -keystore mube-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mube
```

#### Configurar o keystore:
1. Copie o arquivo `android/key.properties.template` para `android/key.properties`
2. Preencha os valores no arquivo:
```properties
storePassword=SUA_SENHA_DO_KEYSTORE
keyPassword=SUA_SENHA_DA_CHAVE
keyAlias=mube
storeFile=/caminho/para/mube-release-key.jks
```

⚠️ **IMPORTANTE**: Nunca commit o arquivo `key.properties` ou o keystore no repositório!

### 2. Gerar Build de Release

#### APK (para testes):
```bash
flutter build apk --release
```
O APK será gerado em: `build/app/outputs/flutter-apk/app-release.apk`

#### App Bundle (para Play Store):
```bash
flutter build appbundle --release
```
O AAB será gerado em: `build/app/outputs/bundle/release/app-release.aab`

### 3. Deploy automatizado com Fastlane

Arquivos adicionados:

- `Gemfile`
- `android/fastlane/Appfile`
- `android/fastlane/Fastfile`
- `android/fastlane/README.md`

#### Conta de servico do Google Play

1. No Google Play Console, crie uma service account com permissao para releases
2. Baixe o JSON e salve localmente fora do versionamento
3. Exporte o caminho antes de rodar o Fastlane:

```bash
export PLAY_STORE_JSON_KEY="$PWD/android/fastlane/play-store-service-account.json"
```

Tambem e aceito `SUPPLY_JSON_KEY`.

#### Instalar dependencias Ruby

```bash
bundle install
```

Se estiver no WSL com o repo em `/mnt/c`, use path seguro do Bundler:

```bash
BUNDLE_IGNORE_CONFIG=1 BUNDLE_PATH="$HOME/.bundle_mube" bundle install
```

#### Lanes disponiveis

Teste interno:

```bash
cd android
bundle exec fastlane android internal
```

Closed testing / beta:

```bash
cd android
bundle exec fastlane android beta
```

Teste fechado:

```bash
cd android
bundle exec fastlane android closed
```

Se a track fechada no Google Play Console tiver nome customizado:

```bash
export PLAY_STORE_CLOSED_TRACK="nome-da-sua-track"
cd android
bundle exec fastlane android closed
```

Producao:

```bash
cd android
bundle exec fastlane android production
```

### 4. Fluxo recomendado para teste fechado (Play Store)

Use este caminho para evitar erros de configuracao:

1. Garantir dependencias do ambiente atual:

```bash
flutter pub get
bundle install
```

No WSL com repo em `/mnt/c`:

```bash
flutter pub get
BUNDLE_IGNORE_CONFIG=1 BUNDLE_PATH="$HOME/.bundle_mube" bundle install
```

2. Exportar a conta de servico:

```bash
export PLAY_STORE_JSON_KEY="$PWD/android/fastlane/play-store-service-account.json"
```

3. Enviar para teste fechado (track padrao `alpha`):

```bash
cd android
bundle exec fastlane android closed
```

Se a track fechada tiver outro nome no Play Console:

```bash
export PLAY_STORE_CLOSED_TRACK="nome-da-track-fechada"
cd android
bundle exec fastlane android closed
```

Notas importantes:
- A lane `closed` publica no closed testing e usa o App Bundle gerado em release.
- Execute a lane a partir de `android/` para o Fastlane encontrar `android/fastlane/Fastfile`.
- No WSL, se o Bundler falhar por permissao em `vendor/bundle`, rode com `BUNDLE_IGNORE_CONFIG=1 BUNDLE_PATH="$HOME/.bundle_mube"`.

Validacao sem publicar:

```bash
cd android
bundle exec fastlane android production validate_only:true
```

### 5. Rota alternativa: gerar o AAB em checkout limpo sem Fastlane

Use esta rota quando o ambiente atual nao tiver Ruby/Bundler/Fastlane disponiveis, mas voce ainda precisar gerar o artefato de Android para teste fechado.

Importante:
- esta rota gera o `.aab` pronto para upload manual no Google Play Console
- ela nao publica automaticamente no track `closed`
- use um checkout limpo para nao embutir alteracoes locais nao commitadas no artefato

Passo a passo:

1. Criar um worktree limpo no commit que sera publicado:

```bash
git worktree add --detach ../AppMube_release_<versao> HEAD
```

2. Copiar os arquivos locais necessarios para signing e Firebase Android:

```bash
cp android/key.properties ../AppMube_release_<versao>/android/key.properties
cp android/upload-keystore.jks ../AppMube_release_<versao>/android/upload-keystore.jks
cp android/app/upload-keystore.jks ../AppMube_release_<versao>/android/app/upload-keystore.jks
cp android/app/google-services.json ../AppMube_release_<versao>/android/app/google-services.json
```

3. No Windows, rodar o build de release no worktree limpo:

```powershell
cd C:\Users\Victor\Desktop\AppMube_release_<versao>
flutter pub get
flutter build appbundle --release
```

4. O artefato sera gerado em:

```text
build/app/outputs/bundle/release/app-release.aab
```

5. Opcionalmente, copie o arquivo final para um caminho mais estavel no repo principal:

```bash
mkdir -p build/releases
cp ../AppMube_release_<versao>/build/app/outputs/bundle/release/app-release.aab \
  build/releases/mube-<versao>-closed.aab
```

Quando possivel, continue preferindo a rota oficial com Fastlane, porque ela faz o upload direto para o track fechado. Esta rota alternativa existe para destravar o build quando o ambiente de upload nao estiver pronto.

### 6. Rota alternativa: upload direto para a Play Console sem Fastlane

Se o `.aab` ja estiver gerado e o bloqueio for apenas o ambiente de upload, use o script Node do projeto para publicar direto pela Google Play Developer API.

Pre-requisitos:
- `android/fastlane/play-store-service-account.json` disponivel localmente
- `.aab` ja gerado

Exemplo para o track fechado padrao do projeto (`alpha`):

```bash
node scripts/upload_play_store_release.mjs \
  --aab build/releases/mube-1.3.0+19-closed.aab \
  --track alpha \
  --status draft \
  --name "1.3.0 (19)"
```

Opcoes suportadas:
- `--aab`: caminho do bundle
- `--track`: track do Google Play
- `--status`: `draft`, `completed`, `inProgress` ou `halted`
- `--package`: package name Android
- `--json-key`: service account JSON
- `--name`: nome exibido no release

Observacoes:
- o script abre um `edit`, sobe o bundle, atualiza o track e faz o `commit`
- se o app estiver configurado para enviar mudancas automaticamente para review, o script detecta isso e refaz o `commit` sem `changesNotSentForReview`
- essa rota evita dependencias de Ruby/Bundler/Fastlane quando o objetivo for apenas publicar o artefato ja pronto

---

## Deploy Firebase

### Wrapper padrao

Para qualquer deploy Firebase a partir da raiz, use:

```powershell
.\deploy-firebase.ps1 --only firestore:rules
.\deploy-firebase.ps1 --only firestore:indexes
.\deploy-firestore.ps1
.\deploy-firebase.ps1 --only hosting
```

Esse wrapper usa automaticamente o projeto padrao definido em `.firebaserc` e o arquivo `firebase.deploy.json`, evitando o aviso do campo `flutter` presente no `firebase.json`.

Para o caso mais comum de Firestore, voce tambem pode usar:

```powershell
.\deploy-firestore.ps1
```

### Cloud Functions

Da raiz do projeto, use o wrapper:

```powershell
.\deploy-functions.ps1
```

Para publicar só uma função:

```powershell
.\deploy-functions.ps1 --only functions:manageBandInvite
```

O script usa automaticamente o projeto padrão definido em `.firebaserc` e o arquivo `firebase.deploy.json`.

---

## Configuração iOS

### 1. Configurar Signing no Xcode

1. Abra o projeto no Xcode:
```bash
open ios/Runner.xcworkspace
```

2. Selecione o projeto "Runner" no navegador
3. Vá para a aba "Signing & Capabilities"
4. Selecione sua equipe de desenvolvedor
5. Verifique se o Bundle Identifier está correto: `com.mube.mubeoficial`

### 2. Gerar Build de Release

#### Via Xcode (recomendado):
1. No Xcode, selecione "Product" > "Archive"
2. Quando o archive for criado, clique em "Distribute App"
3. Selecione "App Store Connect" e siga as instruções

#### Via linha de comando:
```bash
flutter build ipa --release --export-method app-store
```

### 3. Deploy automatizado com Fastlane (TestFlight)

Arquivos adicionados:

- `ios/fastlane/Appfile`
- `ios/fastlane/Fastfile`
- `ios/fastlane/README.md`
- `scripts/release_ios.sh`

#### Variaveis de ambiente

Exporte antes de rodar upload:

```bash
export ASC_KEY_ID="SEU_KEY_ID"
export ASC_ISSUER_ID="SEU_ISSUER_ID"
export ASC_KEY_FILEPATH="$HOME/.appstoreconnect/private_keys/AuthKey_XXXXXX.p8"
```

#### Lanes disponiveis

Gerar IPA:

```bash
bundle exec fastlane ios build_ipa
```

Upload de IPA existente:

```bash
bundle exec fastlane ios upload_testflight
```

Build + upload:

```bash
bundle exec fastlane ios beta
```

#### Wrapper recomendado (raiz do repo)

```bash
scripts/release_ios.sh build_ipa
scripts/release_ios.sh upload_testflight
scripts/release_ios.sh beta
```

Notas importantes:
- O upload usa App Store Connect API key (sem login interativo Apple ID no terminal).
- O wrapper valida `ASC_KEY_ID`, `ASC_ISSUER_ID` e `ASC_KEY_FILEPATH` antes de subir.
- O arquivo `.p8` nao deve ficar no repositorio (use caminho seguro local).

---

## Versionamento

O versionamento segue o padrão: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

Exemplo: `1.0.0+1`

- **MAJOR**: Mudanças grandes, incompatíveis com versões anteriores
- **MINOR**: Novas funcionalidades, compatíveis com versões anteriores
- **PATCH**: Correções de bugs
- **BUILD_NUMBER**: Número incremental do build

Para atualizar a versão, edite o arquivo `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

---

## Otimizações de Build

### Android
- **ProGuard/R8**: Habilitado para reduzir o tamanho do APK
- **Shrink Resources**: Remove recursos não utilizados
- **Minify**: Ofusca o código

### iOS
- **Bitcode**: Habilitado por padrão
- **Strip Debug Symbols**: Remove símbolos de debug

---

## Troubleshooting

### Android

#### Erro: "Keystore file not found"
Verifique se o caminho no `key.properties` está correto e se o arquivo existe.

#### Erro: "Invalid keystore format"
O keystore pode estar corrompido. Tente criar um novo ou restaurar de backup.

### iOS

#### Erro: "No valid signing identity"
Verifique se os certificados estão instalados e se a equipe está selecionada no Xcode.

#### Erro: "Provisioning profile not found"
Baixe o provisioning profile do Apple Developer Portal e instale no Xcode.

---

## Publicação

### Google Play Store
1. Acesse o [Google Play Console](https://play.google.com/console)
2. Crie uma nova release
3. Faça upload do arquivo `.aab` gerado
4. Preencha as informações da release e publique

### Apple App Store
1. Acesse o [App Store Connect](https://appstoreconnect.apple.com)
2. Selecione o app e vá para "App Store" > "iOS App"
3. Crie uma nova versão
4. O build deve aparecer automaticamente (se enviado via Xcode)
5. Preencha as informações e envie para revisão

---

## Recursos Adicionais

- [Documentação Flutter - Build e Release](https://docs.flutter.dev/deployment/android)
- [Documentação Flutter - iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
