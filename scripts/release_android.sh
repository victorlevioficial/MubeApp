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

json_key="${PLAY_STORE_JSON_KEY:-${SUPPLY_JSON_KEY:-}}"
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

bundle exec fastlane android "$lane"
