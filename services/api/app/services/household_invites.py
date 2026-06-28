from __future__ import annotations

import hashlib
import hmac
import secrets

from app.core.config import get_settings

_CODE_ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
_CODE_PREFIX = "HL"
_CODE_BODY_LENGTH = 20


def create_household_invite_code() -> str:
    """Creates a shareable, human-readable code with about 100 bits of entropy."""
    body = "".join(secrets.choice(_CODE_ALPHABET) for _ in range(_CODE_BODY_LENGTH))
    return f"{_CODE_PREFIX}-{body[:4]}-{body[4:8]}-{body[8:12]}-{body[12:16]}-{body[16:]}"


def normalize_household_invite_code(code: str) -> str | None:
    normalized = "".join(character for character in code.upper() if character.isalnum())
    if not normalized.startswith(_CODE_PREFIX) or len(normalized) != len(_CODE_PREFIX) + _CODE_BODY_LENGTH:
        return None
    if any(character not in _CODE_ALPHABET for character in normalized[len(_CODE_PREFIX) :]):
        return None
    return normalized


def household_invite_code_hash(code: str) -> str | None:
    normalized = normalize_household_invite_code(code)
    if normalized is None:
        return None

    settings = get_settings()
    payload = f"homeledger:household-invite:v1:{normalized}".encode("utf-8")
    return hmac.new(
        settings.invite_code_secret.encode("utf-8"),
        payload,
        hashlib.sha256,
    ).hexdigest()
