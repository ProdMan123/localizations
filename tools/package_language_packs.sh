#!/usr/bin/env bash
# Zip signed *.scomm-langpack directories and write languages.json when missing.
#
# Usage:
#   ./tools/package_language_packs.sh build/language_packs l10n-v1 scomm-public/localizations
set -euo pipefail

ROOT="${1:?pack root}"
TAG="${2:?release tag e.g. l10n-v1}"
REPO="${3:-scomm-public/localizations}"

if [[ ! -f "$ROOT/languages.json" ]]; then
  echo "languages.json missing under $ROOT; build packs first" >&2
  exit 1
fi

shopt -s nullglob
for pack_dir in "$ROOT"/*.scomm-langpack; do
  [[ -d "$pack_dir" ]] || continue
  locale="$(basename "$pack_dir" .scomm-langpack)"
  zip_path="$(cd "$ROOT" && pwd)/${locale}.scomm-langpack.zip"
  rm -f "$zip_path"
  (cd "$pack_dir" && zip -r -q "$zip_path" manifest.json strings.json)
  sha256="$(openssl dgst -sha256 -hex "$zip_path" | awk '{print $2}')"
  url="https://github.com/$REPO/releases/download/$TAG/${locale}.scomm-langpack.zip"
  python3 - <<PY
import json
from pathlib import Path

root = Path("$ROOT")
index = json.loads((root / "languages.json").read_text(encoding="utf-8"))
for lang in index.get("languages", []):
    if lang.get("locale") == "$locale" and not lang.get("bundled"):
        lang["sha256"] = "$sha256"
        lang["url"] = "$url"
        break
else:
    raise SystemExit(f"locale $locale not found in languages.json")
(root / "languages.json").write_text(json.dumps(index, indent=2) + "\\n", encoding="utf-8")
PY
  echo "Packaged $zip_path sha256=$sha256"
done

echo "Updated $ROOT/languages.json zip hashes"
