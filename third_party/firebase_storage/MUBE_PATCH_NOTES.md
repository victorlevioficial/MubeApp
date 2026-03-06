# Mube Patch Notes

Upstream baseline: `firebase_storage` `13.0.5` from pub.dev.

Comparison reference:

- compared against `~/.pub-cache/hosted/pub.dev/firebase_storage-13.0.5`
- reviewed on `2026-03-06`

## Meaningful local delta

- Android:
  - [TaskStateChannelStreamHandler.kt](/mnt/c/Users/Victor/Desktop/AppMube/third_party/firebase_storage/android/src/main/kotlin/io/flutter/plugins/firebase/storage/TaskStateChannelStreamHandler.kt)
  - `onCancel()` no longer calls `androidTask.cancel()` when the Dart event stream is torn down.
  - practical effect: a finished or otherwise settled task is not turned into a synthetic cancel just because the Flutter listener was disposed.

## Local workspace noise that is not product logic

- `.dart_tool/`
- `pubspec.lock`
- generated/example registrant files under `example/`
- local environment files such as `local.properties`

## Notes

- `windows/CMakeLists.txt` currently differs only in formatting/whitespace, not in confirmed runtime behavior.
- Other Android file diffs observed in comparison were not carrying a confirmed behavioral change beyond the task cancel lifecycle adjustment above.

## Exit criteria

- confirm that upstream `firebase_storage` no longer needs the task stream teardown patch
- remove the override in root `pubspec.yaml`
- rerun app upload/download flows and `flutter test`
