# Dependency Governance

Objetivo: manter dependencias sensiveis sob controle explicito, com criterio claro para permanencia, upgrade e remocao.

## Politica

- Toda entrada em `dependency_overrides` precisa ter:
  - origem upstream
  - versao base local
  - pontos de uso no app
  - motivo de permanencia
  - criterio de saida
- Mudancas em `third_party/` nao entram "silenciosamente".
  - o delta precisa ser descrito no PR/commit ou em nota tecnica adjacente
- Antes de cada release:
  - revisar se cada override ainda e necessario
  - rodar `flutter test`
  - validar build Android e iOS
  - confirmar que nao ha override legado sem dono claro

## Inventario Atual

Data de referencia: 2026-03-06

### `firebase_storage`

- Declaracao: [pubspec.yaml](/mnt/c/Users/Victor/Desktop/AppMube/pubspec.yaml:125)
- Origem local: [third_party/firebase_storage/pubspec.yaml](/mnt/c/Users/Victor/Desktop/AppMube/third_party/firebase_storage/pubspec.yaml:1)
- Nota de patch local: [MUBE_PATCH_NOTES.md](/mnt/c/Users/Victor/Desktop/AppMube/third_party/firebase_storage/MUBE_PATCH_NOTES.md:1)
- Versao local: `13.0.5`
- Upstream declarado pelo proprio pacote:
  - `https://github.com/firebase/flutterfire/tree/main/packages/firebase_storage/firebase_storage`
- Uso principal no app:
  - [storage_repository.dart](/mnt/c/Users/Victor/Desktop/AppMube/lib/src/features/storage/data/storage_repository.dart:15)
  - [gallery_video_player.dart](/mnt/c/Users/Victor/Desktop/AppMube/lib/src/features/profile/presentation/widgets/gallery_video_player.dart:5)
- Risco:
  - fork de plugin FlutterFire aumenta custo de upgrade e risco de divergencia nativa
- Criterio de saida:
  - substituir pelo pacote oficial sem override ou documentar delta inevitavel do fork

### `video_compress`

- Declaracao: [pubspec.yaml](/mnt/c/Users/Victor/Desktop/AppMube/pubspec.yaml:127)
- Origem local: [third_party/video_compress/pubspec.yaml](/mnt/c/Users/Victor/Desktop/AppMube/third_party/video_compress/pubspec.yaml:1)
- Nota de patch local: [MUBE_PATCH_NOTES.md](/mnt/c/Users/Victor/Desktop/AppMube/third_party/video_compress/MUBE_PATCH_NOTES.md:1)
- Versao local: `3.1.4`
- Upstream declarado pelo proprio pacote:
  - `https://github.com/jonataslaw/VideoCompress`
- Uso principal no app:
  - [media_picker_service.dart](/mnt/c/Users/Victor/Desktop/AppMube/lib/src/features/profile/presentation/services/media_picker_service.dart:7)
  - [video_trim_screen.dart](/mnt/c/Users/Victor/Desktop/AppMube/lib/src/features/profile/presentation/widgets/video_trim_screen.dart:9)
- Risco:
  - plugin de video com superficie nativa amplia risco de regressao em build e runtime
- Criterio de saida:
  - migrar para upstream sem override ou consolidar uma alternativa unica para compressao

### `flutter_native_video_trimmer`

- Declaracao: [pubspec.yaml](/mnt/c/Users/Victor/Desktop/AppMube/pubspec.yaml:129)
- Origem local: [third_party/flutter_native_video_trimmer/pubspec.yaml](/mnt/c/Users/Victor/Desktop/AppMube/third_party/flutter_native_video_trimmer/pubspec.yaml:1)
- Nota de patch local: [MUBE_PATCH_NOTES.md](/mnt/c/Users/Victor/Desktop/AppMube/third_party/flutter_native_video_trimmer/MUBE_PATCH_NOTES.md:1)
- Versao local: `1.1.9`
- Upstream declarado pelo proprio pacote:
  - `https://github.com/iawtk2302/flutter_native_video_trimmer`
- Uso principal no app:
  - [video_trim_screen.dart](/mnt/c/Users/Victor/Desktop/AppMube/lib/src/features/profile/presentation/widgets/video_trim_screen.dart:6)
- Risco:
  - plugin nativo pouco centralizado tende a acumular patch local e encarecer manutencao
- Criterio de saida:
  - eliminar o fork ou substituir por fluxo de trim que compartilhe manutencao com a camada de compressao

## Watchlist

### `flutter_markdown`

- Declaracao: [pubspec.yaml](/mnt/c/Users/Victor/Desktop/AppMube/pubspec.yaml:83)
- Uso atual:
  - [legal_detail_screen.dart](/mnt/c/Users/Victor/Desktop/AppMube/lib/src/features/legal/presentation/legal_detail_screen.dart:2)
- Motivo de monitoramento:
  - dependencia concentrada em uma tela, com custo relativamente baixo de substituicao
- Decisao pratica:
  - manter por enquanto
  - revalidar manutencao, compatibilidade e necessidade na proxima revisao de dependencias

## Plano de Saida

1. Criar uma nota curta de delta para cada fork em `third_party/`.
2. Priorizar primeiro os forks de video, porque concentram maior risco nativo.
3. Revisar `firebase_storage` junto do proximo upgrade de Firebase/FlutterFire.
4. Remover overrides um a um, sempre com teste focado da feature e `flutter test` completo.

## Gate de Release

Nenhuma release deve sair com override novo ou modificado sem responder estas perguntas:

- Qual problema real o fork resolve?
- Onde esse fork e usado no app?
- Qual e o criterio objetivo para removelo?
- O delta local esta documentado?
