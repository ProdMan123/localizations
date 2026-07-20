#!/usr/bin/env bash
# Generate an Ed25519 key pair for language-pack signing.
#
# Usage:
#   ./tools/gen-signing-key.sh l10n-k1
#   OUT_DIR=~/secure/l10n-keys ./tools/gen-signing-key.sh l10n-k2

set -euo pipefail

KEY_ID="${1:-}"
if [[ -z "$KEY_ID" || ! "$KEY_ID" =~ ^[a-z][a-z0-9-]{1,31}$ ]]; then
  echo "Usage: $0 <key-id>   (example: l10n-k1)" >&2
  exit 64
fi

OUT_DIR="${OUT_DIR:-${HOME}/.scomm/l10n-signing-keys}"
mkdir -p "$OUT_DIR"

PRIVATE="$OUT_DIR/${KEY_ID}-private.pem"
PUBLIC="$OUT_DIR/${KEY_ID}-public.pem"

if [[ -f "$PRIVATE" ]]; then
  echo "Refusing to overwrite existing private key: $PRIVATE" >&2
  exit 1
fi

command -v openssl >/dev/null || { echo "OpenSSL not found" >&2; exit 1; }

openssl genpkey -algorithm ED25519 -out "$PRIVATE"
openssl pkey -in "$PRIVATE" -pubout -out "$PUBLIC"

SECRET_SUFFIX="$(echo "$KEY_ID" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
SECRET_NAME="L10N_SIGNING_PRIVATE_KEY_${SECRET_SUFFIX}"
ASSET="assets/l10n_pack_signing_${KEY_ID}_public.pem"

cat <<EOF

Key id:        $KEY_ID
Private key:   $PRIVATE
Public key:    $PUBLIC
GitHub secret: $SECRET_NAME
App asset:     $ASSET

Next steps:
  1. Add secret $SECRET_NAME to scomm-public/localizations (full private PEM).
  2. Copy public PEM to secMail0/$ASSET
  3. Register key id in LanguagePackSigningKeys.trustedPublicKeyAssets

EOF
