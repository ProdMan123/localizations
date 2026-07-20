# Language pack signing (Ed25519)

Language packs and the `languages.json` index can be signed with **Ed25519**
so the SComm app can verify Release assets before install.

## Key id and rotation

Each key pair has a stable **key id** (for example `l10n-k1`). The id is stored
in signed metadata so the app picks the matching bundled public key.

When rotating:

1. Generate a new pair with a new id (for example `l10n-k2`).
2. Add the new **private** PEM as a GitHub secret (keep the old secret).
3. Ship a new app build with **both** public keys in
   `LanguagePackSigningKeys.trustedPublicKeyAssets`.
4. Sign new releases with the new key; old packs remain valid until retired.

## Generate a key pair (OpenSSL)

From any machine with OpenSSL 3.x:

```powershell
# PowerShell (Windows)
.\tools\gen-signing-key.ps1 -KeyId l10n-k1
```

```bash
# Bash
./tools/gen-signing-key.sh l10n-k1
```

Or manually:

```bash
KEY_ID=l10n-k1
openssl genpkey -algorithm ED25519 -out "${KEY_ID}-private.pem"
openssl pkey -in "${KEY_ID}-private.pem" -pubout -out "${KEY_ID}-public.pem"
```

**Never commit `*-private.pem`.** Copy the public PEM into the application repo
as `assets/l10n_pack_signing_<keyId>_public.pem` and register it in
`LanguagePackSigningKeys.trustedPublicKeyAssets`.

## GitHub Actions secrets

Repository: [scomm-public/localizations](https://github.com/scomm-public/localizations)

| Secret | Value |
|--------|--------|
| `L10N_SIGNING_PRIVATE_KEY_L10N_K1` | Full PEM of `l10n-k1-private.pem` (including `BEGIN`/`END` lines) |
| `SECMAIL_READ_TOKEN` | PAT or GitHub App token with **read** access to the application repo (used to checkout ARBs during CI) |

The application repo uses `LOCALIZATIONS_PUBLISH_TOKEN` to dispatch the
**Build, sign, and publish language packs** workflow on release tags.

Secret names follow `L10N_SIGNING_PRIVATE_KEY_<KEY_ID>` where `<KEY_ID>` is the
key id uppercased with dashes replaced by underscores (`l10n-k1` → `L10N_K1`).

Optional workflow variable for the active signing key:

| Name | Example |
|------|---------|
| `L10N_SIGNING_KEY_ID` | `l10n-k1` |

## Signed payload (format v1)

When signing is enabled, `manifest.json` gains optional fields:

| Field | Type | Notes |
|-------|------|--------|
| `signatureKeyId` | string | e.g. `l10n-k1` |
| `signatureAlgorithm` | string | `Ed25519` |
| `signature` | string | Base64 (standard, no URL-safe alphabet) of 64-byte Ed25519 signature |

**Message signed** (UTF-8 bytes, no trailing newline):

```text
scomm-langpack-v1\0<signatureKeyId>\0<locale>\0<packVersion>\0<stringsSha256>
```

- `stringsSha256` is the lowercase hex SHA-256 of `strings.json` (required when
  signing; must match the `stringsSha256` field in the same manifest).
- Sign with OpenSSL raw mode over those bytes.

Example (after building a pack):

```bash
STRINGS_SHA=$(openssl dgst -sha256 -hex strings.json | awk '{print $2}')
MSG=$'scomm-langpack-v1\0l10n-k1\0de\01.0.0\0'"$STRINGS_SHA"
printf '%s' "$MSG" > /tmp/sign-input.bin
openssl pkeyutl -sign \
  -inkey l10n-k1-private.pem -rawin \
  -in /tmp/sign-input.bin \
  | openssl base64 -A
```

Verify locally:

```bash
printf '%s' "$MSG" > /tmp/sign-input.bin
echo "$SIGNATURE_B64" | openssl base64 -d -A > /tmp/sign.sig
openssl pkeyutl -verify \
  -pubin -inkey l10n-k1-public.pem -rawin \
  -in /tmp/sign-input.bin -sigfile /tmp/sign.sig
```

## App behavior

- Packs **without** signature fields remain installable (legacy / unsigned).
- When `signatureKeyId` is present, the app MUST verify the signature against
  a bundled trusted public key before activation.
- Unknown key ids or failed verification MUST fail closed (keep prior pack).

See also [PACK_FORMAT.md](PACK_FORMAT.md) and the app’s
`LanguagePackSigningKeys` / `LanguagePackSecurity` modules.
