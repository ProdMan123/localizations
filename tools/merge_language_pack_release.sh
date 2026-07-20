#!/usr/bin/env bash
# Seed [pack_root] from an existing GitHub Release (for partial rebuilds).
#
# Usage:
#   ./tools/merge_language_pack_release.sh dist/language_packs l10n-latest
set -euo pipefail

ROOT="${1:?pack root directory}"
TAG="${2:-l10n-latest}"
REPO="${3:-scomm-public/localizations}"

mkdir -p "$ROOT"

if ! gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
  echo "No existing release $TAG; starting fresh"
  exit 0
fi

gh release download "$TAG" -R "$REPO" -D "$ROOT" \
  --pattern 'languages.json' \
  --pattern '*.scomm-langpack.zip' \
  --clobber

echo "Merged prior release $TAG into $ROOT"
