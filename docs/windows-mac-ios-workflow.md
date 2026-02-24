# Fluxo Windows + MacBook (iPhone/App Store)

Este eh o fluxo oficial do projeto para evitar bagunca e retrabalho.

## 1) Setup unico (fazer uma vez em cada maquina)

1. Instalar FVM
   - Windows (PowerShell): `dart pub global activate fvm`
   - macOS (Terminal): `dart pub global activate fvm`
2. Na raiz do projeto, fixar versao do Flutter
   - `fvm use 3.38.6`
3. Instalar dependencias
   - `fvm flutter pub get`

## 2) Regras obrigatorias

1. Nao desenvolver direto na `main`.
2. Trabalhar em branch `feature/...`.
3. Abrir PR para `develop`.
4. So vai para `main` quando for release.

## 3) Fluxo diario no Windows (desenvolvimento)

1. Atualizar base
   - `git checkout develop`
   - `git pull origin develop`
2. Criar branch
   - `git checkout -b feature/nome-curto`
3. Trabalhar e testar
   - `fvm flutter pub get`
   - `fvm flutter run`
4. Enviar para GitHub
   - `git add .`
   - `git commit -m "feat: descricao curta"`
   - `git push -u origin feature/nome-curto`

## 4) Fluxo no MacBook (teste real iPhone)

1. Baixar a mesma branch
   - `git fetch origin`
   - `git checkout feature/nome-curto`
   - `git pull`
2. Preparar iOS
   - `fvm flutter pub get`
   - `cd ios && pod install && cd ..`
3. Rodar no iPhone
   - `fvm flutter run -d <iphone_id>`
   - ou abrir `ios/Runner.xcworkspace` no Xcode e rodar por la
4. Achou bug no iPhone
   - Corrigir no Mac na mesma branch
   - Commit/push na mesma branch

## 5) Pull Request e merge

1. Abrir PR de `feature/...` para `develop`.
2. Esperar CI verde (analyze, test, build-android, build-ios).
3. Fazer merge com `Squash and merge`.

## 6) Release para App Store

1. Quando `develop` estiver estavel, abrir PR `develop -> main`.
2. Merge na `main`.
3. No Mac, gerar archive no Xcode e enviar para App Store Connect.

## 7) Hotfix urgente

1. Criar branch de `main`: `hotfix/...`.
2. Corrigir, testar no iPhone, abrir PR para `main`.
3. Depois fazer merge de volta para `develop` para manter tudo sincronizado.
