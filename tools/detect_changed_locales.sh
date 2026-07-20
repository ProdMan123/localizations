#!/usr/bin/env bash
# Emit comma-separated locale codes for changed translation sources.
#
# Usage:
#   ./tools/detect_changed_locales.sh [before_sha] [after_sha]
#   ./tools/detect_changed_locales.sh --all
#
# Scans catalog/, full/, and bootstrap/ for app_<locale>.arb changes.
# If app_en.arb changed, prints "ALL".
set -euo pipefail

if [ "${1:-}" = "--all" ]; then
  echo "ALL"
  exit 0
fi

BEFORE="${1:-}"
AFTER="${2:-HEAD}"
PATHS=(catalog full bootstrap)

if [ -z "$BEFORE" ] || [ "$BEFORE" = "0000000000000000000000000000000000000000" ]; then
  echo "ALL"
  exit 0
fi

mapfile -t CHANGED < <(
  git diff --name-only "$BEFORE" "$AFTER" -- "${PATHS[@]}" 2>/dev/null \
    | grep -E '(catalog|full|bootstrap)/app_[a-z]{2,8}\.arb$' || true
)

if ((${#CHANGED[@]} == 0)); then
  exit 0
fi

if printf '%s\n' "${CHANGED[@]}" | grep -q 'app_en\.arb$'; then
  echo "ALL"
  exit 0
fi

locales=()
for file in "${CHANGED[@]}"; do
  base="$(basename "$file" .arb)"
  locale="${base#app_}"
  locales+=("$locale")
done

printf '%s' "$(printf '%s\n' "${locales[@]}" | sort -u | paste -sd, -)"
