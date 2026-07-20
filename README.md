# SComm localizations

Public repository that **hosts SComm.ai language packs** for download.

- **Org/repo:** [scomm-public/localizations](https://github.com/scomm-public/localizations)
- **License:** Apache-2.0
- **Distribution:** [GitHub Releases](https://github.com/scomm-public/localizations/releases) (not the git tree)

Clients fetch:

1. `languages.json` — index of available locales, versions, URLs, and SHA-256 hashes  
2. `<locale>.scomm-langpack.zip` — zip of `manifest.json` + `strings.json`

Example Release asset URLs:

```text
https://github.com/scomm-public/localizations/releases/download/l10n-v1/<locale>.scomm-langpack.zip
https://github.com/scomm-public/localizations/releases/download/l10n-v1/languages.json
```

## Repository layout

```text
catalog/          Canonical English + locale translation sources (ARB / JSON)
bootstrap/        Optional bootstrap-only string subsets (onboarding / auth)
full/             Optional full-catalog sources used to build packs
glossary/         Shared terminology for translators
schema/           JSON schemas for languages.json and pack manifests
docs/             Pack format and publishing documentation
.github/workflows Publishing / validation workflows (as added)
```

Built packs are **not** committed to `main`. They are uploaded as **Release assets**
when a localization release tag is published (for example `l10n-v1`).

## Pack format (`.scomm-langpack`)

Unzipped layout:

```text
de.scomm-langpack/
  manifest.json
  strings.json
```

See [docs/PACK_FORMAT.md](docs/PACK_FORMAT.md).

## Relationship to the app

| Concern | Repository |
|---------|------------|
| App binary, gen_l10n bootstrap, runtime loader | Application repo (e.g. `advcomm-DevOps/secMail`) |
| Public downloadable full language packs | **This repo** |

English remains bundled in the application. Non-English full catalogs are
intended to be downloadable from this repo’s Releases.

## Contributing

1. Prefer PRs that update sources under `catalog/` (or locale-specific paths).  
2. Do not commit built `.zip` packs to git.  
3. Human-reviewed strings should be marked locked in metadata so automated
   translation does not overwrite them (see app tooling docs).

## App integration

The SComm app:

1. Bundles **bootstrap** strings for auth / onboarding / pack UI in many locales  
2. Fetches this repo’s latest `languages.json`  
3. Downloads allowlisted `*.scomm-langpack.zip` Release assets on user request  

Index URL:

```text
https://github.com/scomm-public/localizations/releases/latest/download/languages.json
```

## Status

Structure is in place. Release assets appear after the app CI publishes on an
app `v*` tag (Release tag `l10n-<app-tag>`), or after a manual upload via
**Publish language packs** workflow.
