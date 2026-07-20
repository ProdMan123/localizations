#!/usr/bin/env bash
# Sign unpacked .scomm-langpack directories with Ed25519 (OpenSSL 3.x).
#
# Usage:
#   export L10N_SIGNING_PRIVATE_KEY_L10N_K1="$(cat ~/.scomm/l10n-signing-keys/l10n-k1-private.pem)"
#   export L10N_SIGNING_KEY_ID=l10n-k1
#   ./tools/sign_language_packs.sh build/language_packs
#
# Updates manifest.json in each pack dir with signatureKeyId, signatureAlgorithm,
# signature, and stringsSha256 (required for signing).
set -euo pipefail

ROOT="${1:?pack root directory (contains *.scomm-langpack folders)}"
KEY_ID="${L10N_SIGNING_KEY_ID:-l10n-k1}"
SECRET_SUFFIX="$(echo "$KEY_ID" | tr '[:lower:]-' '[:upper:]_')"
ENV_NAME="L10N_SIGNING_PRIVATE_KEY_${SECRET_SUFFIX}"

if [[ -z "${!ENV_NAME:-}" ]]; then
  echo "Missing private key env: $ENV_NAME" >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL 3.x is required" >&2
  exit 1
fi

KEY_FILE="$(mktemp)"
SIGN_INPUT="$(mktemp)"
cleanup() { rm -f "$KEY_FILE" "$SIGN_INPUT"; }
trap cleanup EXIT

printf '%s\n' "${!ENV_NAME}" > "$KEY_FILE"

shopt -s nullglob
pack_dirs=("$ROOT"/*.scomm-langpack)
if ((${#pack_dirs[@]} == 0)); then
  echo "No *.scomm-langpack directories under $ROOT" >&2
  exit 1
fi

for pack_dir in "${pack_dirs[@]}"; do
  [[ -d "$pack_dir" ]] || continue
  manifest="$pack_dir/manifest.json"
  strings="$pack_dir/strings.json"
  if [[ ! -f "$manifest" || ! -f "$strings" ]]; then
    echo "Skipping incomplete pack: $pack_dir" >&2
    continue
  fi

  read -r locale pack_version strings_sha < <(
    python3 - <<'PY' "$manifest" "$strings"
import hashlib
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
strings_path = Path(sys.argv[2])
strings_sha = hashlib.sha256(strings_path.read_bytes()).hexdigest()
print(manifest["locale"], manifest["packVersion"], strings_sha)
PY
  )

  python3 - <<PY
key_id = "$KEY_ID"
locale = "$locale"
pack_version = "$pack_version"
strings_sha = "$strings_sha"
  payload = (
      "scomm-langpack-v1\x00"
      + key_id
      + "\x00"
      + locale
      + "\x00"
      + pack_version
      + "\x00"
      + strings_sha
  ).encode("utf-8")
open("$SIGN_INPUT", "wb").write(payload)
PY

  signature_b64="$(
    openssl pkeyutl -sign -inkey "$KEY_FILE" -rawin -in "$SIGN_INPUT" | openssl base64 -A
  )"

  python3 - <<PY
import json
from pathlib import Path

path = Path("$manifest")
data = json.loads(path.read_text(encoding="utf-8"))
data["stringsSha256"] = "$strings_sha"
data["signatureKeyId"] = "$KEY_ID"
data["signatureAlgorithm"] = "Ed25519"
data["signature"] = "$signature_b64"
path.write_text(json.dumps(data, indent=2) + "\\n", encoding="utf-8")
PY

  echo "Signed $pack_dir ($locale)"
done

echo "Signed ${#pack_dirs[@]} pack(s) with key $KEY_ID"
