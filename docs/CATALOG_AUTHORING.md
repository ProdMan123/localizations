# Catalog authoring (local only)

Full-catalog AI translation and human locking run **on your PC**. There is no
GitHub Actions workflow and no repository secret for an AI API key.

After you push `catalog/` changes to `main`, **Build, sign, and publish**
rebuilds `l10n-latest` automatically.

## Prerequisites

- Clone this repo next to the application repo (for `app_en.arb`), or pass any
  path to English.
- Optional: an OpenAI-compatible API key in your **local** environment only.

```powershell
# PowerShell (session only — do not commit)
$env:L10N_AI_API_KEY = "sk-..."
# optional:
$env:L10N_AI_BASE_URL = "https://api.openai.com/v1"
$env:L10N_AI_MODEL = "gpt-4o-mini"
```

```bash
export L10N_AI_API_KEY=sk-...
export L10N_AI_BASE_URL=https://api.openai.com/v1   # optional
export L10N_AI_MODEL=gpt-4o-mini                     # optional
```

## AI translate unlocked keys

Dry-run (no API key):

```bash
python tools/l10n_ai_translate.py \
  --english-arb ../secMail0/lib/core/localizations/l10n/app_en.arb \
  --locales de,fr \
  --dry-run
```

Translate and write `catalog/app_*.arb`:

```bash
python tools/l10n_ai_translate.py \
  --english-arb ../secMail0/lib/core/localizations/l10n/app_en.arb \
  --locales de,fr
```

Omit `--locales` to process every catalog locale. Human-locked keys are never
changed.

## Lock human-reviewed keys

```bash
python tools/l10n_lock_human.py --locale de --keys someKey,otherKey
python tools/l10n_lock_human.py --locale de --from-git-diff main
python tools/l10n_lock_human.py --locale de --all-non-english \
  --english-arb ../secMail0/lib/core/localizations/l10n/app_en.arb
```

## Push

```bash
git checkout -b l10n/de-ai
git add catalog/
git commit -m "l10n(de): AI translate unlocked catalog keys"
git push -u origin HEAD
# open a PR, or merge to main to trigger pack publish
```
