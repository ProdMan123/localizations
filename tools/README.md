# Tools

## Catalog authoring (local only)

| Script | Purpose |
|--------|---------|
| `l10n_ai_translate.py` | AI-fill unlocked keys in `catalog/` (needs `app_en.arb`) |
| `l10n_lock_human.py` | Mark catalog keys human-locked |
| `arb_lock.py` | Shared lock / provenance helpers |

Set `L10N_AI_API_KEY` in your local shell (never as a GitHub secret), run the
scripts, then commit and push. See [docs/CATALOG_AUTHORING.md](../docs/CATALOG_AUTHORING.md).

## Pack build / publish

Packs are built in CI (`build-sign-publish.yml`) using the application repo’s
`tool/publish_language_packs.dart` against a merged ARB catalog
(`prepare_arb_catalog.sh`).

## Signing keys

Generate Ed25519 key pairs for pack signing (private key → GitHub secret,
public key → app asset):

- `tools/gen-signing-key.ps1 -KeyId l10n-k1`
- `tools/gen-signing-key.sh l10n-k1`

Sign unpacked pack directories before zipping (CI or local):

- `tools/sign_language_packs.sh build/language_packs`
- `tools/package_language_packs.sh build/language_packs l10n-v1`

See [docs/SIGNING.md](../docs/SIGNING.md).
