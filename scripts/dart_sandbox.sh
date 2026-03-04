#!/usr/bin/env bash
set -euo pipefail

# Sandbox-safe Dart entrypoint for this workspace.
# It bypasses /home/victor/flutter/bin/dart, which tries to write to
# Flutter's global cache outside the writable sandbox roots.

exec /home/victor/flutter/bin/cache/dart-sdk/bin/dart "$@"
