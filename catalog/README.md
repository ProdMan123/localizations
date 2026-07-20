# Catalog

Canonical full-catalog translation sources for downloadable language packs.

Layout:

```text
catalog/
  app_de.arb
  app_ja.arb
  …
```

These ARBs are machine-translated first-cut catalogs (≈1182 keys) used by the
**Build, sign, and publish** workflow. Human-reviewed strings should be marked
with `x-scomm-source: human` / `x-scomm-locked: true` so automated tools do not
overwrite them.

Built `.scomm-langpack.zip` files must **not** be committed here; they are
published via GitHub Releases (`l10n-latest`).
