# Mube Patch Notes

Upstream baseline: `video_compress` `3.1.4` from pub.dev.

Comparison reference:

- compared against `~/.pub-cache/hosted/pub.dev/video_compress-3.1.4`
- reviewed on `2026-03-06`

## Meaningful local delta

- Android:
  - [VideoCompressPlugin.kt](/mnt/c/Users/Victor/Desktop/AppMube/third_party/video_compress/android/src/main/kotlin/com/example/video_compress/VideoCompressPlugin.kt)
  - wraps `compressVideo` setup in `try/catch`
  - adds structured `Log.i` / `Log.w` / `Log.e` breadcrumbs for:
    - input parameters
    - trim mode
    - destination path
    - completion, cancel and failure
  - practical effect: startup/configuration failures fail soft with `null` instead of bubbling as an uncaught plugin crash, and debugging compression issues is materially easier

## Local workspace noise that is not product logic

- `.dart_tool/`
- `pubspec.lock`
- generated/example registrant files

## Exit criteria

- verify if upstream plugin or alternative media pipeline already covers the same robustness/logging needs
- remove the override in root `pubspec.yaml`
- rerun trim/compress flows on Android before release
