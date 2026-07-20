# SComm language pack format

## Archive

- Extension: `.scomm-langpack.zip` (zip of a single pack folder)
- Folder name: `<locale>.scomm-langpack`
- Allowed files only:
  - `manifest.json`
  - `strings.json`

No executables, nested archives, or scripts.

## `manifest.json`

| Field | Type | Required | Notes |
|-------|------|----------|--------|
| `formatVersion` | int | yes | Currently `1` |
| `locale` | string | yes | Language code `^[a-z]{2,8}$` (e.g. `de`, `ja`) |
| `displayName` | string | yes | English / international label |
| `nativeName` | string | yes | Native label |
| `packVersion` | string | yes | Per-locale pack version |
| `catalogVersion` | int | yes | Catalog generation this pack was built from |
| `stringCount` | int | yes | Number of entries in `strings.json` |
| `stringsSha256` | string | recommended | Hex SHA-256 of `strings.json` UTF-8 bytes |
| `appMinVersion` | string | no | Minimum app semver |
| `direction` | string | no | `ltr` or `rtl` (also listed in `languages.json`) |
| `signatureKeyId` | string | no | Signing key id (e.g. `l10n-k1`); see [SIGNING.md](SIGNING.md) |
| `signatureAlgorithm` | string | no | `Ed25519` when signed |
| `signature` | string | no | Base64 Ed25519 signature over the v1 signing payload |

## `strings.json`

Flat JSON object: message key → translated string.

- Keys match the app’s English ARB message identifiers.
- Preserve ICU placeholders such as `{count}` and `{email}`.
- Missing keys fall back to bundled English in the app.

## Integrity

When `stringsSha256` is present, installers MUST verify it before activation.
Failed verification MUST leave any previously installed pack intact.
