# Tools

Pack-building and validation scripts may live here, or packs may be built from
the application repository and only **published** to this repo’s Releases.

Until dedicated tooling is added, use the application repo helpers:

- `tool/build_language_pack.dart`
- `tool/publish_language_packs.dart --repository scomm-public/localizations`
- `tool/validate_l10n.dart`

## Signing keys

Generate Ed25519 key pairs for pack signing (private key → GitHub secret,
public key → app asset):

- `tools/gen-signing-key.ps1 -KeyId l10n-k1`
- `tools/gen-signing-key.sh l10n-k1`

Sign unpacked pack directories before zipping (CI or local):

- `tools/sign_language_packs.sh build/language_packs`
- `tools/package_language_packs.sh build/language_packs l10n-v1`

See [docs/SIGNING.md](../docs/SIGNING.md).
