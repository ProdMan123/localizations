#!/usr/bin/env python3
"""AI-translate unlocked keys in catalog/ ARBs (OpenAI-compatible API).

Run on your local PC, then commit/push catalog changes. There is no GitHub
Actions workflow and no repository AI secret — set L10N_AI_API_KEY in your
shell only. See docs/CATALOG_AUTHORING.md.

English template is taken from --english-arb (usually the app's app_en.arb).
Never overwrites human-locked keys. Does not publish language packs.

Usage:
  python tools/l10n_ai_translate.py \\
    --english-arb /path/to/app_en.arb \\
    [--locales de,fr] [--dry-run]

Env (local only):
  L10N_AI_API_KEY   (required unless --dry-run)
  L10N_AI_BASE_URL  (default https://api.openai.com/v1)
  L10N_AI_MODEL     (default gpt-4o-mini)
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from arb_lock import (  # noqa: E402
    ensure_placeholder_metadata,
    mark_ai_translated,
    may_ai_translate,
    message,
    message_keys,
)

ROOT = _TOOLS.parent
CATALOG = ROOT / "catalog"


def load_arb(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def save_arb(path: Path, data: dict) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def discover_locales() -> list[str]:
    locales: list[str] = []
    for path in sorted(CATALOG.glob("app_*.arb")):
        loc = path.stem.removeprefix("app_")
        if loc != "en":
            locales.append(loc)
    return locales


def translate_batch(
    *,
    api_key: str,
    base_url: str,
    model: str,
    target_locale: str,
    entries: dict[str, str],
) -> dict[str, str]:
    if not entries:
        return {}
    url = base_url.rstrip("/") + "/chat/completions"
    payload = {
        "model": model,
        "temperature": 0.2,
        "response_format": {"type": "json_object"},
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are a professional software UI translator for the SComm "
                    f'email client. Translate values to locale "{target_locale}". '
                    "Preserve ICU placeholders exactly (e.g. {count}, {email}). "
                    "Do not translate brand names SComm, Scomm, Sentria, Ollama. "
                    "Return JSON object mapping each key to its translation string only."
                ),
            },
            {
                "role": "user",
                "content": json.dumps(
                    {"locale": target_locale, "strings": entries},
                    ensure_ascii=False,
                ),
            },
        ],
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            body = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")[:500]
        raise SystemExit(f"AI API HTTP {e.code}: {detail}") from e

    choices = body.get("choices") or []
    if not choices:
        raise SystemExit("AI API returned no choices")
    content = (choices[0].get("message") or {}).get("content") or ""
    text = content.strip()
    if text.startswith("```"):
        text = text.removeprefix("```json").removeprefix("```").strip()
        if text.endswith("```"):
            text = text[: -3].strip()
    decoded = json.loads(text)
    if isinstance(decoded, dict) and isinstance(decoded.get("strings"), dict):
        decoded = decoded["strings"]
    if not isinstance(decoded, dict):
        raise SystemExit("AI response is not a JSON object")
    out: dict[str, str] = {}
    for key in entries:
        value = decoded.get(key)
        if isinstance(value, str) and value.strip():
            out[key] = value
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--english-arb",
        required=True,
        type=Path,
        help="Path to app_en.arb (usually from application checkout)",
    )
    parser.add_argument(
        "--locales",
        default="",
        help="Comma-separated locales (default: all catalog locales)",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--batch-size", type=int, default=40)
    args = parser.parse_args()

    english_path = args.english_arb
    if not english_path.is_file():
        print(f"Missing English ARB: {english_path}", file=sys.stderr)
        return 1
    english = load_arb(english_path)

    locales = (
        [s.strip() for s in args.locales.split(",") if s.strip()]
        if args.locales
        else discover_locales()
    )
    if not locales:
        print("No catalog locales found.", file=sys.stderr)
        return 1

    api_key = os.environ.get("L10N_AI_API_KEY", "")
    base_url = os.environ.get("L10N_AI_BASE_URL") or "https://api.openai.com/v1"
    model = os.environ.get("L10N_AI_MODEL") or "gpt-4o-mini"
    if not args.dry_run and not api_key:
        print("L10N_AI_API_KEY is required (or pass --dry-run)", file=sys.stderr)
        return 1

    total_candidates = 0
    total_written = 0

    for locale in locales:
        path = CATALOG / f"app_{locale}.arb"
        if not path.is_file():
            print(f"Skipping missing ARB: {path}", file=sys.stderr)
            continue
        locale_arb = load_arb(path)
        candidates: dict[str, str] = {}
        for key in message_keys(english):
            if may_ai_translate(
                english=english, locale_map=locale_arb, key=key
            ):
                candidates[key] = message(english, key)  # type: ignore[assignment]

        print(f"[{locale}] candidates={len(candidates)} (dryRun={args.dry_run})")
        total_candidates += len(candidates)
        if not candidates:
            continue
        if args.dry_run:
            sample = ", ".join(list(candidates)[:10])
            print(f"  sample: {sample}")
            continue

        keys = sorted(candidates)
        for i in range(0, len(keys), args.batch_size):
            batch_keys = keys[i : i + args.batch_size]
            batch = {k: candidates[k] for k in batch_keys}
            print(
                f"  translating batch {i // args.batch_size + 1} "
                f"({len(batch)} keys)…"
            )
            translated = translate_batch(
                api_key=api_key,
                base_url=base_url,
                model=model,
                target_locale=locale,
                entries=batch,
            )
            for key, value in translated.items():
                ensure_placeholder_metadata(english, locale_arb, key)
                locale_arb[key] = value
                mark_ai_translated(locale_arb, key, candidates[key])
                total_written += 1
            missing = [k for k in batch_keys if k not in translated]
            if missing:
                print(
                    f"  warning: AI omitted {len(missing)} keys "
                    f"(first: {missing[0]})",
                    file=sys.stderr,
                )
        save_arb(path, locale_arb)
        print(f"  wrote {path}")

    print(
        f"Done. candidates={total_candidates} written={total_written} "
        f"dryRun={args.dry_run}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
