#!/usr/bin/env bash
# Smoke-test languages.json + one pack download (checksum + string count).
#
# Usage:
#   ./tools/verify_release_download.sh [locale] [min_strings]
# Example:
#   ./tools/verify_release_download.sh de 1000
set -euo pipefail

LOCALE="${1:-de}"
MIN_STRINGS="${2:-1000}"
INDEX_URL="${INDEX_URL:-https://github.com/scomm-public/localizations/releases/latest/download/languages.json}"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

echo "Fetching $INDEX_URL"
curl -fsSL "$INDEX_URL" -o "$WORKDIR/languages.json"
python3 - <<PY
import json
from pathlib import Path

index = json.loads(Path("$WORKDIR/languages.json").read_text(encoding="utf-8"))
langs = {l["locale"]: l for l in index["languages"]}
assert "en" in langs and langs["en"].get("bundled") is True
lang = langs.get("$LOCALE")
assert lang is not None, "locale $LOCALE missing from index"
assert not lang.get("bundled"), "$LOCALE should be downloadable"
assert lang.get("url"), "missing url"
assert lang.get("sha256"), "missing sha256"
Path("$WORKDIR/meta.json").write_text(json.dumps(lang), encoding="utf-8")
print(f"OK index: {len(langs)} languages; will download {lang['url']}")
PY

URL="$(python3 -c "import json; print(json.load(open('$WORKDIR/meta.json'))['url'])")"
EXPECTED="$(python3 -c "import json; print(json.load(open('$WORKDIR/meta.json'))['sha256'])")"
ZIP="$WORKDIR/$LOCALE.scomm-langpack.zip"
curl -fsSL "$URL" -o "$ZIP"

ACTUAL="$(openssl dgst -sha256 -hex "$ZIP" | awk '{print $2}')"
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "SHA mismatch: expected=$EXPECTED actual=$ACTUAL" >&2
  exit 1
fi

unzip -q -o "$ZIP" -d "$WORKDIR/pack"
COUNT="$(python3 -c "import json; print(len(json.load(open('$WORKDIR/pack/strings.json'))))")"
echo "strings=$COUNT min=$MIN_STRINGS"
if [ "$COUNT" -lt "$MIN_STRINGS" ]; then
  echo "Expected at least $MIN_STRINGS strings in full pack" >&2
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path
m = json.loads(Path("$WORKDIR/pack/manifest.json").read_text(encoding="utf-8"))
assert m.get("signatureKeyId"), "pack should be signed"
assert m.get("signature"), "missing signature"
print(f"OK pack: locale={m['locale']} strings={m.get('stringCount')} signed={m.get('signatureKeyId')}")
PY
