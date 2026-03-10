#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ ! -f "${REPO_ROOT}/.fvmrc" ]]; then
  echo "Missing .fvmrc at ${REPO_ROOT}"
  exit 1
fi

FLUTTER_VERSION="$(
  ruby -rjson -e '
    path = ARGV.fetch(0)
    config = JSON.parse(File.read(path))
    version = config.fetch("flutter").to_s.strip
    abort("Missing Flutter version in #{path}") if version.empty?
    puts version
  ' "${REPO_ROOT}/.fvmrc"
)"

FLUTTER_SDK_DIR="${HOME}/flutter/${FLUTTER_VERSION}"

if [[ ! -x "${FLUTTER_SDK_DIR}/bin/flutter" ]]; then
  rm -rf "${FLUTTER_SDK_DIR}"
  git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${FLUTTER_SDK_DIR}"
fi

export PATH="${FLUTTER_SDK_DIR}/bin:${FLUTTER_SDK_DIR}/bin/cache/dart-sdk/bin:${PATH}"
export COCOAPODS_DISABLE_STATS=true

flutter config --no-analytics
flutter --version
flutter precache --ios

pushd "${REPO_ROOT}" >/dev/null
flutter pub get --enforce-lockfile

pushd ios >/dev/null
pod install --repo-update
popd >/dev/null

flutter build ios --release --config-only --no-codesign

popd >/dev/null
