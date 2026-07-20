# Catalog

Canonical full-catalog translation sources for downloadable language packs.

Layout:

```text
catalog/
  app_de.arb
  app_ja.arb
  …
```

These ARBs are machine-translated first-cut catalogs used by the
**Build, sign, and publish** workflow. Author **locally** (no CI):

- `python tools/l10n_ai_translate.py …` — see [docs/CATALOG_AUTHORING.md](../docs/CATALOG_AUTHORING.md)
- `python tools/l10n_lock_human.py …`

Human-reviewed strings should be marked with `x-scomm-source: human` /
`x-scomm-locked: true` so automated tools do not overwrite them.

Built `.scomm-langpack.zip` files must **not** be committed here; they are
published via GitHub Releases (`l10n-latest`).
