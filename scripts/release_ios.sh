#!/usr/bin/env bash

set -euo pipefail

lane="${1:-beta}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$lane" in
  build_ipa|upload_testflight|beta)
    ;;
  *)
    echo "Usage: scripts/release_ios.sh [build_ipa|upload_testflight|beta] [fastlane_options...]"
    exit 1
    ;;
esac

if [[ "$lane" != "build_ipa" ]]; then
  if [[ -z "${ASC_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" || -z "${ASC_KEY_FILEPATH:-}" ]]; then
    echo "Set ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_FILEPATH before running this script."
    exit 1
  fi

  if [[ ! -f "${ASC_KEY_FILEPATH}" ]]; then
    echo "App Store Connect key file not found: ${ASC_KEY_FILEPATH}"
    exit 1
  fi
fi

(
  cd ios
  bundle exec fastlane ios "$lane" "$@"
)
