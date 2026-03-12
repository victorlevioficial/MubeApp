#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_GSP_PATH="$REPO_ROOT/ios/Runner/GoogleService-Info.plist"
DEFAULT_FLUTTER_VERSION="3.38.6"

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

log() {
  echo "[ci_post_clone] $*"
}

detect_flutter_version() {
  if [[ -n "${FLUTTER_VERSION:-}" ]]; then
    printf '%s' "$FLUTTER_VERSION"
    return 0
  fi

  if [[ -f "$REPO_ROOT/.fvmrc" ]]; then
    ruby -rjson -e '
      path = ARGV.fetch(0)
      config = JSON.parse(File.read(path))
      version = config.fetch("flutter").to_s.strip
      abort("Missing Flutter version in #{path}") if version.empty?
      puts version
    ' "$REPO_ROOT/.fvmrc"
    return 0
  fi

  printf '%s' "$DEFAULT_FLUTTER_VERSION"
}

FLUTTER_VERSION="$(detect_flutter_version)"
FLUTTER_ROOT_DIR="${FLUTTER_ROOT_DIR:-$HOME/flutter/$FLUTTER_VERSION}"

resolve_first_non_empty() {
  local var_name
  local value

  for var_name in "$@"; do
    value="${!var_name:-}"
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return 0
    fi
  done

  return 1
}

decode_base64_to_file() {
  local encoded="$1"
  local destination="$2"

  mkdir -p "$(dirname "$destination")"

  if printf '%s' "$encoded" | base64 --decode >"$destination" 2>/dev/null; then
    return 0
  fi

  printf '%s' "$encoded" | base64 -D -o "$destination"
}

ensure_flutter() {
  if [[ ! -x "$FLUTTER_ROOT_DIR/bin/flutter" ]]; then
    log "Installing Flutter $FLUTTER_VERSION into $FLUTTER_ROOT_DIR"
    git clone \
      --depth 1 \
      --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git \
      "$FLUTTER_ROOT_DIR"
  else
    log "Using cached Flutter SDK from $FLUTTER_ROOT_DIR"
  fi

  export PATH="$FLUTTER_ROOT_DIR/bin:$PATH"
  flutter --version
  flutter precache --ios
}

restore_google_service_info() {
  local encoded

  encoded="$(
    resolve_first_non_empty \
      IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64 \
      GOOGLE_SERVICE_INFO_PLIST_BASE64 \
      GOOGLE_SERVICE_INFO_BASE64 || true
  )"

  if [[ -n "$encoded" ]]; then
    log "Restoring ios/Runner/GoogleService-Info.plist from Xcode Cloud secret"
    decode_base64_to_file "$encoded" "$IOS_GSP_PATH"
  fi

  if [[ ! -f "$IOS_GSP_PATH" ]]; then
    log "Missing ios/Runner/GoogleService-Info.plist"
    log "Set IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64 in the Xcode Cloud workflow environment."
    exit 1
  fi

  plutil -lint "$IOS_GSP_PATH"
}

ensure_cocoapods() {
  if ! command -v pod >/dev/null 2>&1; then
    log "CocoaPods is required in the Xcode Cloud environment."
    exit 1
  fi
}

prepare_cocoapods_workspace() {
  if [[ ! -f "$REPO_ROOT/ios/Podfile" ]]; then
    return 0
  fi

  ensure_cocoapods

  cd "$REPO_ROOT/ios"
  log "Running pod install --repo-update"
  pod --version
  pod install --repo-update
  cd "$REPO_ROOT"
}

prepare_flutter_ios_project() {
  local -a build_args

  cd "$REPO_ROOT"

  log "Running flutter pub get --enforce-lockfile"
  flutter pub get --enforce-lockfile
  prepare_cocoapods_workspace

  if [[ -z "${GOOGLE_MAPS_API_KEY:-}" ]]; then
    log "Missing GOOGLE_MAPS_API_KEY in the Xcode Cloud workflow environment."
    exit 1
  fi

  build_args=(build ios --config-only --release --no-codesign --no-pub)
  build_args+=(--dart-define="GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}")

  if [[ -n "${GOOGLE_VISION_API_KEY:-}" ]]; then
    build_args+=(--dart-define="GOOGLE_VISION_API_KEY=${GOOGLE_VISION_API_KEY}")
  fi

  if [[ -n "${APP_CHECK_DEBUG_TOKEN:-}" ]]; then
    build_args+=(--dart-define="APP_CHECK_DEBUG_TOKEN=${APP_CHECK_DEBUG_TOKEN}")
  fi

  log "Preparing iOS project with flutter build ios --config-only"
  flutter "${build_args[@]}"
}

main() {
  log "Bootstrapping Xcode Cloud workspace"
  ensure_flutter
  restore_google_service_info
  prepare_flutter_ios_project
  log "Xcode Cloud workspace is ready for archive"
}

main "$@"
