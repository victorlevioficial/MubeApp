#!/usr/bin/env bash
set -euo pipefail

# Keep the analysis gate focused on the Flutter app workspace.
# Root-level `flutter analyze` is currently unstable in this hybrid workspace
# because auxiliary directories can dominate package scanning time.
python3 "$(cd "$(dirname "$0")/.." && pwd)/scripts/flutter_version.py" --check-current
exec flutter analyze lib test integration_test test_driver scripts
