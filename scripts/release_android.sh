#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
local_env="${project_root}/.env.local"
if [[ -f "${local_env}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${local_env}"
  set +a
fi

lane="${1:-internal}"
shift || true

case "$lane" in
  internal|beta|closed|production)
    ;;
  *)
    echo "Usage: scripts/release_android.sh [internal|beta|closed|production]"
    exit 1
    ;;
esac

default_json_key="${project_root}/android/fastlane/play-store-service-account.json"
json_key="${PLAY_STORE_JSON_KEY:-${SUPPLY_JSON_KEY:-}}"
if [[ -z "${json_key}" && -f "${default_json_key}" ]]; then
  json_key="${default_json_key}"
  export PLAY_STORE_JSON_KEY="${json_key}"
fi
if [[ -z "${json_key}" ]]; then
  echo "Set PLAY_STORE_JSON_KEY or SUPPLY_JSON_KEY before running this script."
  exit 1
fi

if [[ ! -f "${json_key}" ]]; then
  echo "Google Play service account JSON not found: ${json_key}"
  exit 1
fi

if [[ -f "android/key.properties" ]]; then
  store_file="$(awk -F= '/^storeFile=/{print $2}' android/key.properties | tr -d '\r')"
  if [[ -n "${store_file}" ]]; then
    keystore_path="android/${store_file}"
    if [[ ! -f "${keystore_path}" ]]; then
      fallback_path="android/app/$(basename "${store_file}")"
      if [[ -f "${fallback_path}" ]]; then
        echo "Keystore not found at ${keystore_path}. Copying fallback from ${fallback_path}."
        cp -f "${fallback_path}" "${keystore_path}"
      else
        echo "Keystore file not found: ${keystore_path}"
        echo "Checked fallback: ${fallback_path}"
        exit 1
      fi
    fi
  fi
fi

(
  cd "${project_root}/android"
  bundle exec fastlane "$lane" "$@"
)
