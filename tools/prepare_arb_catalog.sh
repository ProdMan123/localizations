#!/usr/bin/env bash
# Merge public-repo translation sources into a single ARB directory for pack builds.
#
# Usage:
#   ./tools/prepare_arb_catalog.sh app/lib/core/localizations/l10n dist/arb_catalog
set -euo pipefail

APP_L10N="${1:?app l10n directory}"
OUT="${2:?output arb directory}"

mkdir -p "$OUT"
shopt -s nullglob

copy_tree() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  for arb in "$dir"/app_*.arb; do
    cp "$arb" "$OUT/"
  done
}

# App bootstrap/full bundled ARBs are the base.
copy_tree "$APP_L10n"
# Public repo overlays (catalog wins over bootstrap/full duplicates).
copy_tree "catalog"
copy_tree "full"
copy_tree "bootstrap"

count="$(find "$OUT" -maxdepth 1 -name 'app_*.arb' | wc -l | tr -d ' ')"
echo "Prepared $count ARB file(s) in $OUT"
