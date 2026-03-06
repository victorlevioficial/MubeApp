# Mube Patch Notes

Upstream baseline: `flutter_native_video_trimmer` `1.1.9` from pub.dev.

Comparison reference:

- compared against `~/.pub-cache/hosted/pub.dev/flutter_native_video_trimmer-1.1.9`
- reviewed on `2026-03-06`

## Meaningful local delta

- Dart API:
  - [video_trimmer.dart](/mnt/c/Users/Victor/Desktop/AppMube/third_party/flutter_native_video_trimmer/lib/src/video_trimmer.dart)
  - [video_trimmer_platform_interface.dart](/mnt/c/Users/Victor/Desktop/AppMube/third_party/flutter_native_video_trimmer/lib/src/video_trimmer_platform_interface.dart)
  - `trimVideo()` now accepts optional `outputWidth` and `outputHeight`
- Method channel:
  - forwards `outputWidth` / `outputHeight` to native layers
- Android and iOS:
  - native trim handlers/managers consume those dimensions
  - practical effect: the app can request bounded trim output resolution instead of relying only on source dimensions

## Repository shape differences

- upstream `example/` and Android test content are not vendored locally
- `.dart_tool/` and `pubspec.lock` are local workspace artifacts

## Exit criteria

- confirm that upstream package exposes output sizing or migrate the app to an alternative trim pipeline
- remove the override in root `pubspec.yaml`
- rerun trim/export flows on Android and iOS before release
