# Bundle Size Analysis & Optimization Guide

## Overview

Este documento apresenta uma análise do tamanho do bundle do MubeApp e recomendações para otimização.

## Tamanho Atual (Estimado)

### Android (APK/AAB)
- **Base APK**: ~25-30MB (sem assets)
- **Com assets**: ~35-45MB
- **Download size** (Google Play): ~20-25MB (com compressão)

### iOS (IPA)
- **Tamanho estimado**: ~40-50MB
- **Download size** (App Store): ~25-30MB

### Breakdown por Categoria

```
Dart Code:           ~40%
Flutter Engine:      ~25%
Firebase SDKs:       ~15%
Assets/Images:       ~10%
Native Libraries:    ~10%
```

## Análise de Dependências

### Dependências Pesadas Identificadas

#### 1. **Firebase Suite** (~5-7MB)
```yaml
firebase_core: ^3.12.1
firebase_auth: ^5.5.1
cloud_firestore: ^6.1.2
firebase_storage: ^12.3.7
firebase_messaging: ^15.2.2
firebase_analytics: ^12.1.1
firebase_crashlytics: ^5.0.7
firebase_remote_config: ^6.1.4
```
**Recomendação**: ✅ Necessário - essencial para o app

#### 2. **Image Processing** (~2-3MB)
```yaml
image: ^4.5.4
cached_network_image: ^3.4.1
```
**Recomendação**: ✅ Necessário - melhora performance de imagens

#### 3. **Video/Audio** (~3-5MB)
```yaml
video_player: ^2.9.2
chewie: ^1.10.0  # Wrapper do video_player
```
**Recomendação**: ⚠️ Verificar uso - se não estiver sendo usado, remover

#### 4. **Location Services** (~1-2MB)
```yaml
geolocator: ^13.0.2
geocoding: ^3.0.0
```
**Recomendação**: ✅ Necessário - funcionalidade core

#### 5. **UI Packages** (~2-3MB)
```yaml
shimmer: ^3.0.0
flutter_slidable: ^4.0.0
flutter_staggered_grid_view: ^0.7.0
```
**Recomendação**: ✅ Necessário - melhoram UX

#### 6. **Development/Debug** (~0.5MB)
```yaml
widgetbook: ^3.11.0
widgetbook_annotation: ^3.3.0
```
**Recomendação**: ✅ Já configurado como dev_dependency

## Recomendações de Otimização

### 1. Remover Dependências Não Usadas

Verificar e remover se não estiverem sendo usadas:

```bash
# Analisar imports não usados
flutter pub run dependency_validator
```

Potenciais candidatos para remoção:
- Verificar `video_player` se realmente está sendo usado
- Verificar `permission_handler` se todas as permissões são necessárias

### 2. Compressão de Assets

#### Imagens
- Usar formato **WebP** para imagens (20-30% menor que PNG/JPEG)
- Comprimir imagens com:
  ```bash
  # Usar o plugin flutter_image_compress
  # Configurar para gerar WebP no build
  ```

#### Configuração no `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/  # Usar WebP quando possível
```

### 3. Code Splitting (Deferred Loading)

Implementar lazy loading para telas pesadas:

```dart
// Antes
import 'package:mube/src/features/admin/presentation/admin_screen.dart';

// Depois
import 'package:mube/src/features/admin/presentation/admin_screen.dart' 
  deferred as admin;

// Uso
FutureBuilder(
  future: admin.loadLibrary(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return admin.AdminScreen();
    }
    return const LoadingWidget();
  },
)
```

**Telas candidatas para lazy loading**:
- Admin screens
- Developer tools
- Settings screens não essenciais

### 4. Otimização de Builds

#### Android
```gradle
// android/app/build.gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt')
        }
    }
}
```

#### iOS
```ruby
# ios/Podfile
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

### 5. Reduzir Tamanho de Imagens

#### Script para otimização:
```bash
#!/bin/bash
# optimize_images.sh

# Instalar ferramentas
# npm install -g imagemin-cli imagemin-webp

# Converter para WebP
for file in assets/images/*.{jpg,png}; do
  imagemin "$file" --plugin=webp > "${file%.*}.webp"
done
```

### 6. Configuração de ProGuard (Android)

Criar `android/app/proguard-rules.pro`:

```proguard
# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }

# Model classes
-keep class com.mube.app.** { *; }
```

### 7. Análise de Bundle

#### Ferramentas para análise:

```bash
# Android - Analisar APK
flutter build apk --analyze-size

# iOS - Analisar IPA
flutter build ios --analyze-size
```

#### Usar DevTools:
```bash
flutter pub global activate devtools
flutter pub global run devtools --appSizeBase=apk-analysis.json
```

## Scripts de Build Otimizados

### Build Android (Release Otimizado)
```bash
#!/bin/bash
# build_android_optimized.sh

flutter clean
flutter pub get

# Build APK otimizado
flutter build apk \
  --release \
  --split-debug-info=build/symbols \
  --obfuscate \
  --shrink \
  --target-platform android-arm64

# Build App Bundle (para Google Play)
flutter build appbundle \
  --release \
  --split-debug-info=build/symbols \
  --obfuscate \
  --shrink
```

### Build iOS (Release Otimizado)
```bash
#!/bin/bash
# build_ios_optimized.sh

flutter clean
flutter pub get

# Build IPA
flutter build ios \
  --release \
  --split-debug-info=build/symbols \
  --obfuscate
```

## Metas de Tamanho

### Curto Prazo (MVP)
- Android: < 30MB download
- iOS: < 40MB download

### Médio Prazo
- Android: < 25MB download
- iOS: < 35MB download

### Longo Prazo
- Android: < 20MB download
- iOS: < 30MB download

## Checklist de Otimização

- [ ] Remover dependências não usadas
- [ ] Comprimir todas as imagens (WebP)
- [ ] Implementar lazy loading para telas admin
- [ ] Configurar ProGuard/R8
- [ ] Habilitar code obfuscation
- [ ] Analisar bundle size mensalmente
- [ ] Documentar novas dependências pesadas

## Monitoramento

### Métricas a Acompanhar
1. **Tamanho do APK/AAB** - Semanal
2. **Tamanho do IPA** - Semanal
3. **Tempo de download** - Mensal (Firebase Performance)
4. **Taxa de abandono** - Mensal (Google Play Console/App Store Connect)

### Alertas
Configurar alertas quando:
- APK > 50MB
- IPA > 60MB
- Aumento de > 10% entre releases

## Recursos

### Documentação
- [Flutter Performance](https://docs.flutter.dev/perf)
- [App Size Best Practices](https://docs.flutter.dev/perf/app-size)
- [Deferred Components](https://docs.flutter.dev/perf/deferred-components)

### Ferramentas
- [APK Analyzer](https://developer.android.com/studio/debug/apk-analyzer)
- [App Thinning](https://developer.apple.com/documentation/xcode/reducing-your-app-s-size)

## Conclusão

O MubeApp está em um tamanho razoável para um app Flutter com Firebase. As principais otimizações devem focar em:

1. **Compressão de assets** (maior impacto)
2. **Lazy loading** de telas não essenciais
3. **Remoção de dependências** não usadas
4. **Monitoramento contínuo** do tamanho

Com estas otimizações, é possível reduzir o tamanho em 20-30%.
