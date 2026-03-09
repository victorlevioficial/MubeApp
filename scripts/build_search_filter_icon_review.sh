#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REVIEW_DIR="$ROOT_DIR/design_review/search_filter_icons"
ICON_DIR="$REVIEW_DIR/icons"
BASE_URL="https://raw.githubusercontent.com/FortAwesome/Font-Awesome/7.x/svgs/solid"
LICENSE_URL="https://raw.githubusercontent.com/FortAwesome/Font-Awesome/7.x/LICENSE.txt"

mkdir -p "$ICON_DIR"

items=(
  "cantores|microphone"
  "guitarristas|guitar"
  "bateristas|drum"
  "baixistas|guitar"
  "djs|compact-disc"
  "tecnicos-de-som|volume-high"
  "tecnicos-de-luz|lightbulb"
  "produtores|sliders"
  "roadies|toolbox"
  "stage-managers|clipboard-list"
  "mixagem-master|volume-high"
  "bandas|people-group"
  "estudios|headset"
  "sertanejo|hat-cowboy"
  "rock|bolt-lightning"
  "gospel|hands-praying"
  "funk-eletronica|record-vinyl"
  "pagode-samba|champagne-glasses"
  "forro-nordeste|sun"
)

for item in "${items[@]}"; do
  IFS='|' read -r local_name remote_name <<< "$item"
  curl -fsSL "$BASE_URL/$remote_name.svg" -o "$ICON_DIR/$local_name.svg"
done

# Custom icons are maintained locally when the upstream free set does not
# provide a good semantic match.
test -f "$ICON_DIR/tecladistas.svg"

curl -fsSL "$LICENSE_URL" -o "$REVIEW_DIR/LICENSE.FontAwesome.txt"

printf 'Search filter icon review assets updated in %s\n' "$REVIEW_DIR"
