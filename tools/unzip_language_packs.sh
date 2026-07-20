#!/usr/bin/env bash
# Expand *.scomm-langpack.zip files into sibling directories under [pack_root].
#
# Usage:
#   ./tools/unzip_language_packs.sh dist/language_packs
set -euo pipefail

ROOT="${1:?pack root}"
shopt -s nullglob

for zip in "$ROOT"/*.scomm-langpack.zip; do
  locale="$(basename "$zip" .scomm-langpack.zip)"
  dir="$ROOT/${locale}.scomm-langpack"
  rm -rf "$dir"
  mkdir -p "$dir"
  unzip -q -o "$zip" -d "$dir"
  echo "Unzipped $locale"
done
