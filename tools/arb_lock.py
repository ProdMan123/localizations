"""ARB lock / provenance helpers (mirrors app ArbLockPolicy)."""

from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from typing import Any

SOURCE_KEY = "x-scomm-source"
LOCKED_KEY = "x-scomm-locked"
LOCKED_AT_KEY = "x-scomm-locked-at"
EN_HASH_KEY = "x-scomm-en-hash"
SOURCE_AI = "ai"
SOURCE_HUMAN = "human"


def message_keys(data: dict[str, Any]) -> list[str]:
    return sorted(k for k in data if not k.startswith("@"))


def message(data: dict[str, Any], key: str) -> str | None:
    value = data.get(key)
    return value if isinstance(value, str) else None


def metadata(data: dict[str, Any], key: str) -> dict[str, Any] | None:
    value = data.get(f"@{key}")
    if isinstance(value, dict):
        return dict(value)
    return None


def set_metadata(data: dict[str, Any], key: str, meta: dict[str, Any]) -> None:
    data[f"@{key}"] = meta


def english_hash(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def is_human_locked(locale_map: dict[str, Any], key: str) -> bool:
    meta = metadata(locale_map, key)
    if meta is None:
        return False
    if meta.get(LOCKED_KEY) is True:
        return True
    if meta.get(SOURCE_KEY) == SOURCE_HUMAN:
        return True
    return False


def may_ai_translate(
    *,
    english: dict[str, Any],
    locale_map: dict[str, Any],
    key: str,
) -> bool:
    if is_human_locked(locale_map, key):
        return False
    en_value = message(english, key)
    if not en_value:
        return False
    local_value = message(locale_map, key)
    if local_value is None or local_value == "":
        return True
    if local_value == en_value:
        return True
    meta = metadata(locale_map, key) or {}
    source = meta.get(SOURCE_KEY)
    if source == SOURCE_HUMAN:
        return False
    if source == SOURCE_AI:
        return meta.get(EN_HASH_KEY) != english_hash(en_value)
    # Existing translation without provenance: do not AI-overwrite.
    return False


def mark_ai_translated(
    locale_map: dict[str, Any],
    key: str,
    english_value: str,
) -> None:
    meta = metadata(locale_map, key) or {}
    meta[SOURCE_KEY] = SOURCE_AI
    meta[LOCKED_KEY] = False
    meta[EN_HASH_KEY] = english_hash(english_value)
    meta.pop(LOCKED_AT_KEY, None)
    set_metadata(locale_map, key, meta)


def mark_human_locked(locale_map: dict[str, Any], key: str) -> None:
    meta = metadata(locale_map, key) or {}
    meta[SOURCE_KEY] = SOURCE_HUMAN
    meta[LOCKED_KEY] = True
    meta[LOCKED_AT_KEY] = datetime.now(timezone.utc).isoformat()
    set_metadata(locale_map, key, meta)


def ensure_placeholder_metadata(
    english: dict[str, Any],
    locale_map: dict[str, Any],
    key: str,
) -> None:
    en_meta = metadata(english, key)
    if en_meta is None:
        return
    local = metadata(locale_map, key) or {}
    for k, v in en_meta.items():
        if str(k).startswith("x-scomm-"):
            continue
        local.setdefault(k, v)
    set_metadata(locale_map, key, local)
