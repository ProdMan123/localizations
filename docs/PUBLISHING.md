# Publishing language packs

## Host

All production packs are published as **GitHub Release assets** on:

[https://github.com/scomm-public/localizations](https://github.com/scomm-public/localizations)

Do **not** use workflow artifacts as the long-lived download location.

## Release tags

Prefer tags of the form:

```text
l10n-v<catalogVersion>
```

Examples: `l10n-v1`, `l10n-v142`

Optionally append a pack revision: `l10n-v142.3`.

## Required assets per Release

| Asset | Purpose |
|-------|---------|
| `languages.json` | Global index (locales, URLs, hashes, bundled flags) |
| `<locale>.scomm-langpack.zip` | One zip per downloadable locale |

## `languages.json` shape

See [schema/languages.schema.json](../schema/languages.schema.json) and the
example under [releases/example-languages.json](../releases/example-languages.json).

Each non-bundled language entry should include:

- `locale`, `nativeName`, `bundled: false`
- `version`, `url`, `sha256`
- optional `direction` (`ltr` / `rtl`)

English is typically listed with `"bundled": true` and no download URL.

## Build source

Packs are built from canonical catalogs (this repo and/or the application
repo’s ARBs) using the app’s tooling, for example:

```bash
dart run tool/build_language_pack.dart --locale de
dart run tool/publish_language_packs.dart \
  --tag l10n-v1 \
  --repository scomm-public/localizations
```

CI should upload the resulting files to the matching GitHub Release.

### Automated pipeline (recommended)

Workflow **Build, sign, and publish language packs**
(`.github/workflows/build-sign-publish.yml`) on this repo:

1. Checks out the application repository
2. Builds pack directories + `languages.json` (`--skip-zip`)
3. Signs each manifest with Ed25519 (`tools/sign_language_packs.sh`)
4. Zips signed packs and refreshes zip SHA-256 entries (`tools/package_language_packs.sh`)
5. Publishes a GitHub Release

Trigger manually (**Actions → Build, sign, and publish language packs**) or from
an application `v*` tag via `repository_dispatch` (see app `.github/workflows/l10n.yml`).

Required secrets: `L10N_SIGNING_PRIVATE_KEY_L10N_K1`, `SECMAIL_READ_TOKEN`.

## Security baseline

- HTTPS only (GitHub Releases)
- Schema validation of manifests / index
- SHA-256 of pack payloads
- Safe zip extraction (no path traversal, allowlisted entries only)
- Optional Ed25519 signing — see [SIGNING.md](SIGNING.md)
