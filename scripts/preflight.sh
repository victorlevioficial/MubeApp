#!/usr/bin/env bash
# Pre-flight validation script for release readiness.
#
# Run this BEFORE pushing a `chore(release):` commit to main. It mirrors
# the CI gate (format, analyze, tests) and adds a few release-only checks
# that CI does not cover: version bump sanity, generated files, TODO scan.
#
# Usage:
#   ./scripts/preflight.sh           # full check
#   ./scripts/preflight.sh --quick   # skip tests (format + analyze only)
#
# Exit code 0 = ready to release. Non-zero = blocker found.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

QUICK=0
if [[ "${1:-}" == "--quick" ]]; then
  QUICK=1
fi

PASS="[OK]"
FAIL="[FAIL]"
WARN="[WARN]"

ERRORS=0
WARNINGS=0

section() {
  echo ""
  echo "=== $1 ==="
}

fail() {
  echo "  $FAIL $1"
  ERRORS=$((ERRORS + 1))
}

warn() {
  echo "  $WARN $1"
  WARNINGS=$((WARNINGS + 1))
}

ok() {
  echo "  $PASS $1"
}

section "1. Flutter/Dart version"
if python3 scripts/flutter_version.py --check-current >/dev/null 2>&1; then
  ok "Flutter version matches pinned value"
else
  fail "Flutter version mismatch (see scripts/flutter_version.py)"
fi

section "2. Working tree clean"
if [[ -z "$(git status --porcelain)" ]]; then
  ok "No uncommitted changes"
else
  warn "Uncommitted changes present (commit or stash before release)"
  git status --short | sed 's/^/    /'
fi

section "3. On main branch"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" == "main" ]]; then
  ok "On main"
else
  warn "Current branch is '$CURRENT_BRANCH' (release commits should land on main)"
fi

section "4. Version bumped"
PUBSPEC_VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
LAST_VERSION="$(git log --pretty=format:'%s' -n 50 | grep -oE 'chore\(release\): [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+' | head -n1 | awk '{print $2}')"
if [[ -z "$LAST_VERSION" ]]; then
  warn "No previous chore(release) commit found in last 50 commits"
elif [[ "$PUBSPEC_VERSION" == "$LAST_VERSION" ]]; then
  fail "pubspec version ($PUBSPEC_VERSION) not bumped since last release ($LAST_VERSION)"
else
  ok "Version $PUBSPEC_VERSION (prev release: $LAST_VERSION)"
fi

section "5. Generated files fresh"
if find lib -name '*.g.dart' -newer pubspec.yaml 2>/dev/null | head -n1 | grep -q .; then
  ok "Generated files newer than pubspec.yaml"
else
  if find lib -name '*.g.dart' | head -n1 | grep -q .; then
    warn "Generated files exist but older than pubspec.yaml (consider running build_runner)"
  else
    warn "No generated files found under lib/ (expected from @riverpod/@freezed)"
  fi
fi

section "6. dart format (CI gate)"
if dart format --output=none --set-exit-if-changed lib test scripts >/dev/null 2>&1; then
  ok "Formatting clean"
else
  fail "dart format would change files — run: dart format lib test scripts"
fi

section "7. flutter analyze (CI gate)"
if flutter analyze --fatal-infos lib test >/tmp/preflight_analyze.log 2>&1; then
  ok "Analyze clean"
else
  fail "Analyze issues found — see /tmp/preflight_analyze.log"
  tail -n 20 /tmp/preflight_analyze.log | sed 's/^/    /'
fi

if [[ $QUICK -eq 0 ]]; then
  section "8. flutter test (CI gate)"
  if flutter test >/tmp/preflight_test.log 2>&1; then
    ok "All tests pass"
  else
    fail "Tests failed — see /tmp/preflight_test.log"
    tail -n 30 /tmp/preflight_test.log | sed 's/^/    /'
  fi
else
  section "8. flutter test (SKIPPED in --quick mode)"
  warn "Run full preflight before pushing to main"
fi

section "9. Secrets scan (basic)"
if git diff HEAD~1..HEAD --name-only 2>/dev/null | xargs grep -l -E '(AIza[0-9A-Za-z_-]{35}|sk_live_|AKIA[0-9A-Z]{16})' 2>/dev/null | head -n1 | grep -q .; then
  fail "Possible secrets in last commit diff"
else
  ok "No obvious secret patterns in last commit"
fi

section "10. Firestore rules deployable"
if [[ -f firestore.rules ]]; then
  ok "firestore.rules present"
else
  warn "firestore.rules missing"
fi

section "11. TODO/FIXME in critical paths"
CRITICAL_TODOS=$(grep -rE '(TODO|FIXME|XXX).*(release|ship|block|prod)' lib/src 2>/dev/null | wc -l | tr -d ' ')
if [[ "$CRITICAL_TODOS" -eq 0 ]]; then
  ok "No release-blocking TODOs in lib/src"
else
  warn "$CRITICAL_TODOS potentially release-blocking TODOs — review:"
  grep -rnE '(TODO|FIXME|XXX).*(release|ship|block|prod)' lib/src 2>/dev/null | head -n 5 | sed 's/^/    /'
fi

section "12. Android release signing"
if [[ -f android/key.properties ]]; then
  ok "android/key.properties present"
else
  warn "android/key.properties missing (required for signed build)"
fi

section "Summary"
echo ""
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "  $PASS All checks passed. Ready for release."
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo "  $WARN Passed with $WARNINGS warning(s). Review before releasing."
  exit 0
else
  echo "  $FAIL $ERRORS blocker(s), $WARNINGS warning(s). Fix before releasing."
  exit 1
fi
