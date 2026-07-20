#!/usr/bin/env python3
"""Mark catalog ARB keys as human-locked so AI never overwrites them.

Usage:
  python tools/l10n_lock_human.py --locale de --keys inbox,compose
  python tools/l10n_lock_human.py --locale de --all-non-english \\
    --english-arb /path/to/app_en.arb
  python tools/l10n_lock_human.py --locale de --from-git-diff main
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from arb_lock import mark_human_locked, message, message_keys  # noqa: E402

ROOT = _TOOLS.parent
CATALOG = ROOT / "catalog"


def load_arb(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def save_arb(path: Path, data: dict) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def keys_from_git_diff(locale: str, base_ref: str) -> set[str]:
    path = f"catalog/app_{locale}.arb"
    result = subprocess.run(
        ["git", "diff", "--unified=0", base_ref, "--", path],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        raise SystemExit(f"git diff failed for {path}")
    keys: set[str] = set()
    for match in re.finditer(r'^\+\s*"([^"@][^"]*)"\s*:', result.stdout, re.M):
        keys.add(match.group(1))
    return keys


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--locale", required=True)
    parser.add_argument("--keys", default="", help="Comma-separated keys")
    parser.add_argument("--all-non-english", action="store_true")
    parser.add_argument("--from-git-diff", default=None, metavar="REF")
    parser.add_argument(
        "--english-arb",
        type=Path,
        help="Required with --all-non-english (app_en.arb path)",
    )
    args = parser.parse_args()

    path = CATALOG / f"app_{args.locale}.arb"
    if not path.is_file():
        print(f"Missing ARB: {path}", file=sys.stderr)
        return 1
    locale_arb = load_arb(path)

    keys: set[str] = set()
    if args.keys:
        keys.update(k.strip() for k in args.keys.split(",") if k.strip())
    if args.all_non_english:
        if args.english_arb is None or not args.english_arb.is_file():
            print("--english-arb is required with --all-non-english", file=sys.stderr)
            return 1
        english = load_arb(args.english_arb)
        for key in message_keys(english):
            local = message(locale_arb, key)
            en = message(english, key)
            if local and en and local != en:
                keys.add(key)
    if args.from_git_diff:
        keys.update(keys_from_git_diff(args.locale, args.from_git_diff))

    if not keys:
        print("No keys selected to lock.", file=sys.stderr)
        return 1

    locked = 0
    for key in sorted(keys):
        value = message(locale_arb, key)
        if value is None or value == "":
            print(f"Skipping empty translation: {key}", file=sys.stderr)
            continue
        mark_human_locked(locale_arb, key)
        locked += 1

    save_arb(path, locale_arb)
    print(
        f"Locked {locked} key(s) in {path} as human "
        "(x-scomm-locked=true, x-scomm-source=human)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
