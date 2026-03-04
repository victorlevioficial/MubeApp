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
- `scripts/release_android.sh`

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

#### Lanes disponiveis

Teste interno:

```bash
bundle exec fastlane android internal
```

Closed testing / beta:

```bash
bundle exec fastlane android beta
```

Teste fechado:

```bash
bundle exec fastlane android closed
```

Se a track fechada no Google Play Console tiver nome customizado:

```bash
export PLAY_STORE_CLOSED_TRACK="nome-da-sua-track"
bundle exec fastlane android closed
```

Producao:

```bash
bundle exec fastlane android production
```

Wrapper opcional:

```bash
scripts/release_android.sh internal
scripts/release_android.sh beta
scripts/release_android.sh closed
scripts/release_android.sh production
```

Validacao sem publicar:

```bash
bundle exec fastlane android production validate_only:true
```

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
5. Verifique se o Bundle Identifier está correto: `com.mube.app`

### 2. Gerar Build de Release

#### Via Xcode (recomendado):
1. No Xcode, selecione "Product" > "Archive"
2. Quando o archive for criado, clique em "Distribute App"
3. Selecione "App Store Connect" e siga as instruções

#### Via linha de comando:
```bash
flutter build ios --release
```

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
