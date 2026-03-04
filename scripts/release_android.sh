#!/usr/bin/env bash

set -euo pipefail

lane="${1:-internal}"

case "$lane" in
  internal|beta|closed|production)
    ;;
  *)
    echo "Usage: scripts/release_android.sh [internal|beta|closed|production]"
    exit 1
    ;;
esac

if [[ -z "${PLAY_STORE_JSON_KEY:-${SUPPLY_JSON_KEY:-}}" ]]; then
  echo "Set PLAY_STORE_JSON_KEY or SUPPLY_JSON_KEY before running this script."
  exit 1
fi

bundle exec fastlane android "$lane"
