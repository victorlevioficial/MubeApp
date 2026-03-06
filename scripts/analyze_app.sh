#!/usr/bin/env bash
set -euo pipefail

# Keep the analysis gate focused on the Flutter app workspace.
# Root-level `flutter analyze` is currently unstable in this hybrid workspace
# because auxiliary directories can dominate package scanning time.
exec flutter analyze lib test integration_test test_driver scripts
