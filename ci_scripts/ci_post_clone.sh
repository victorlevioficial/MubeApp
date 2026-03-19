#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_GSP_PATH="$REPO_ROOT/ios/Runner/GoogleService-Info.plist"
IOS_GSP_TEMPLATE_PATH="$REPO_ROOT/ios/Runner/GoogleService-Info.ci.plist"
DEFAULT_FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
DEFAULT_PUB_HOSTED_URL="https://pub.flutter-io.cn"

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

log() {
  echo "[ci_post_clone] $*"
}

run_with_retry() {
  local max_attempts="$1"
  local sleep_seconds="$2"
  shift 2

  local attempt=1
  local exit_code=0

  while (( attempt <= max_attempts )); do
    if "$@"; then
      return 0
    else
      exit_code=$?
    fi
    if (( attempt == max_attempts )); then
      return "$exit_code"
    fi

    log "Command failed with exit code $exit_code. Retrying in ${sleep_seconds}s (attempt ${attempt}/${max_attempts})"
    sleep "$sleep_seconds"
    attempt=$((attempt + 1))
  done

  return "$exit_code"
}

configure_flutter_network_fallback() {
  export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-$DEFAULT_FLUTTER_STORAGE_BASE_URL}"
  export PUB_HOSTED_URL="${PUB_HOSTED_URL:-$DEFAULT_PUB_HOSTED_URL}"
  log "Using Flutter mirror FLUTTER_STORAGE_BASE_URL=$FLUTTER_STORAGE_BASE_URL"
  log "Using Dart package host PUB_HOSTED_URL=$PUB_HOSTED_URL"
}

run_flutter_command() {
  if flutter "$@"; then
    return 0
  fi

  if [[ -n "${FLUTTER_STORAGE_BASE_URL:-}" ]]; then
    return 1
  fi

  log "Flutter command failed with the default storage host. Retrying with mirror."
  configure_flutter_network_fallback
  flutter "$@"
}

detect_flutter_version() {
  if [[ -n "${FLUTTER_VERSION:-}" ]]; then
    printf '%s' "$FLUTTER_VERSION"
    return 0
  fi

  if [[ -f "$REPO_ROOT/scripts/flutter_version.py" ]]; then
    python3 "$REPO_ROOT/scripts/flutter_version.py" --repo-root "$REPO_ROOT"
    return 0
  fi

  log "Missing Flutter version resolver at scripts/flutter_version.py"
  exit 1
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
    run_with_retry 3 15 \
      git clone \
        --depth 1 \
        --branch "$FLUTTER_VERSION" \
        https://github.com/flutter/flutter.git \
        "$FLUTTER_ROOT_DIR"
  else
    log "Using cached Flutter SDK from $FLUTTER_ROOT_DIR"
  fi

  export PATH="$FLUTTER_ROOT_DIR/bin:$PATH"
  run_flutter_command --version
  python3 "$REPO_ROOT/scripts/flutter_version.py" \
    --repo-root "$REPO_ROOT" \
    --check-current
  run_flutter_command precache --ios
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
  elif [[ ! -f "$IOS_GSP_PATH" && -f "$IOS_GSP_TEMPLATE_PATH" ]]; then
    log "Using versioned CI fallback for ios/Runner/GoogleService-Info.plist"
    cp "$IOS_GSP_TEMPLATE_PATH" "$IOS_GSP_PATH"
  fi

  if [[ ! -f "$IOS_GSP_PATH" ]]; then
    log "Missing ios/Runner/GoogleService-Info.plist"
    log "Commit ios/Runner/GoogleService-Info.ci.plist or set IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64 in the Xcode Cloud workflow environment."
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
  log "Running pod install --deployment"
  pod --version

  if run_with_retry 3 20 pod install --deployment; then
    cd "$REPO_ROOT"
    return 0
  fi

  log "pod install --deployment failed. Retrying without deployment mode."
  run_with_retry 2 30 pod install
  cd "$REPO_ROOT"
}

prepare_flutter_ios_project() {
  local -a build_args

  cd "$REPO_ROOT"

  log "Running flutter pub get --enforce-lockfile"
  run_flutter_command pub get --enforce-lockfile
  prepare_cocoapods_workspace

  build_args=(build ios --config-only --release --no-codesign --no-pub)

  if [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]]; then
    build_args+=(--dart-define="GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}")
  else
    log "Warning: GOOGLE_MAPS_API_KEY is missing in the Xcode Cloud workflow environment."
    log "Continuing without the dart-define; location and geocoding flows will be degraded in this archive."
  fi

  if [[ -n "${GOOGLE_VISION_API_KEY:-}" ]]; then
    build_args+=(--dart-define="GOOGLE_VISION_API_KEY=${GOOGLE_VISION_API_KEY}")
  fi

  if [[ -n "${APP_CHECK_DEBUG_TOKEN:-}" ]]; then
    build_args+=(--dart-define="APP_CHECK_DEBUG_TOKEN=${APP_CHECK_DEBUG_TOKEN}")
  fi

  log "Preparing iOS project with flutter build ios --config-only"
  run_flutter_command "${build_args[@]}"
}

main() {
  log "Bootstrapping Xcode Cloud workspace"
  ensure_flutter
  restore_google_service_info
  prepare_flutter_ios_project
  log "Xcode Cloud workspace is ready for archive"
}

main "$@"
