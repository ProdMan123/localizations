#!/usr/bin/env bash
# Copy freshly built pack dirs/zips into [pack_root] and patch languages.json entries.
#
# Usage:
#   ./tools/overlay_built_packs.sh /path/to/new/build/language_packs dist/language_packs l10n-latest
set -euo pipefail

SRC="${1:?new build output}"
DEST="${2:?pack root}"
TAG="${3:?release tag}"

python3 - <<'PY' "$SRC" "$DEST" "$TAG"
import json
import shutil
import sys
from pathlib import Path

src = Path(sys.argv[1])
dest = Path(sys.argv[2])
tag = sys.argv[3]

dest.mkdir(parents=True, exist_ok=True)

index_path = dest / "languages.json"
if index_path.exists():
    index = json.loads(index_path.read_text(encoding="utf-8"))
else:
    index = {"schemaVersion": 1, "catalogVersion": 1, "releaseTag": tag, "languages": []}

by_locale = {lang["locale"]: lang for lang in index.get("languages", [])}

for pack_dir in sorted(src.glob("*.scomm-langpack")):
    locale = pack_dir.name.removesuffix(".scomm-langpack")
    target_dir = dest / pack_dir.name
    if target_dir.exists():
        shutil.rmtree(target_dir)
    shutil.copytree(pack_dir, target_dir)

    zip_src = src / f"{locale}.scomm-langpack.zip"
    if zip_src.exists():
        shutil.copy2(zip_src, dest / zip_src.name)

new_index = json.loads((src / "languages.json").read_text(encoding="utf-8"))
for lang in new_index.get("languages", []):
    locale = lang["locale"]
    if locale == "en":
        by_locale.setdefault(locale, lang)
        continue
    if lang.get("bundled"):
        continue
    lang["url"] = (
        f"https://github.com/scomm-public/localizations/releases/download/{tag}/"
        f"{locale}.scomm-langpack.zip"
    )
    by_locale[locale] = lang

index["releaseTag"] = tag
index["languages"] = sorted(by_locale.values(), key=lambda x: x["locale"])
index_path.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
print(f"Overlay complete: {len(by_locale)} languages in {index_path}")
PY
