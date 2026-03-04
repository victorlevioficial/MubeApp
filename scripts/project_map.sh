#!/usr/bin/env bash
set -euo pipefail

OUT=".codex/AUTO_MAP.md"
echo "# AUTO MAP (generated)" > "$OUT"
echo "" >> "$OUT"
echo "Generated on: $(date)" >> "$OUT"
echo "" >> "$OUT"

echo "## Pubspec" >> "$OUT"
if [ -f pubspec.yaml ]; then
  grep -nE "^(name:|description:|environment:|dependencies:|dev_dependencies:)" -n pubspec.yaml >> "$OUT" || true
fi
echo "" >> "$OUT"

echo "## Feature folders" >> "$OUT"
ls -1 lib/src/features 2>/dev/null | sed 's/^/- /' >> "$OUT" || echo "- (not found)" >> "$OUT"
echo "" >> "$OUT"

echo "## Providers (Riverpod)" >> "$OUT"
rg -n "Provider<|StateProvider<|NotifierProvider<|FutureProvider<|StreamProvider<|riverpod" lib/src 2>/dev/null \
  | head -n 200 >> "$OUT" || echo "(none found)" >> "$OUT"
echo "" >> "$OUT"

echo "## Routes / Navigation hints" >> "$OUT"
rg -n "GoRouter|MaterialApp|Navigator|routes:|onGenerateRoute" lib/src 2>/dev/null \
  | head -n 200 >> "$OUT" || echo "(none found)" >> "$OUT"
echo "" >> "$OUT"

echo "## Screens (Widgets ending with Screen/Page)" >> "$OUT"
rg -n "class .*?(Screen|Page)\b" lib/src 2>/dev/null \
  | head -n 200 >> "$OUT" || echo "(none found)" >> "$OUT"
echo "" >> "$OUT"

echo "## Firebase usage" >> "$OUT"
rg -n "FirebaseAuth|FirebaseFirestore|FirebaseStorage|FirebaseDatabase|cloud_functions|firestore" lib/src 2>/dev/null \
  | head -n 200 >> "$OUT" || echo "(none found)" >> "$OUT"
echo "" >> "$OUT"

echo "Wrote $OUT"
